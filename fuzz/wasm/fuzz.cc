#include <xrpld/app/wasm/HostFuncImpl.h>
#include <xrpld/app/wasm/HostFuncWrapper.h>
#include <xrpld/app/wasm/HostFunc.h>
#include <test/jtx.h>
#include "FuzzerSuite.h"
#include <xrpl/beast/utility/Journal.h>
#include <xrpl/protocol/Indexes.h>

namespace {

// Global state - initialized once
struct FuzzerGlobalState {
    std::unique_ptr<fuzzer::FuzzerSuite> suite;

    FuzzerGlobalState() {
        suite = std::make_unique<fuzzer::FuzzerSuite>();
    }
};

FuzzerGlobalState& getGlobalState() {
    static FuzzerGlobalState state;
    return state;
}

// Create pre-populated ledger environment
std::unique_ptr<ripple::test::jtx::Env> createFuzzerEnv() {
    using namespace ripple::test::jtx;

    auto& state = getGlobalState();

    auto env = std::make_unique<Env>(
        *state.suite,
        envconfig(),
        testable_amendments()
    );

    // Pre-populate with accounts
    Account const alice("alice");
    Account const bob("bob");
    Account const carol("carol");

    env->fund(XRP(10000), alice, bob, carol);
    env->close();

    // Create escrows for testing
    auto const finishTime = env->now() + std::chrono::seconds(1);
    env->apply(escrow(*env, alice, bob, XRP(100)),
               finish_time(finishTime));
    env->close();

    return env;
}

// Create ApplyContext for WASM execution
ripple::ApplyContext createFuzzerApplyContext(
    ripple::test::jtx::Env& env,
    ripple::OpenView& ov)
{
    using namespace ripple;
    using namespace ripple::test::jtx;

    STTx tx(ttESCROW_FINISH, [&](STObject& obj) {
        obj.setAccountID(sfAccount, env.master.id());
        obj.setFieldU32(sfSequence, env.seq(env.master));
        obj.setFieldAmount(sfFee, env.current()->fees().base);
    });

    ApplyContext ac{
        env.app(),
        ov,
        tx,
        tesSUCCESS,
        env.current()->fees().base,
        tapNONE,
        env.journal
    };

    return ac;
}

} // anonymous namespace

extern "C" int
LLVMFuzzerTestOneInput(uint8_t const* ptr, size_t size)
{
    if (size < 8) return 0;

    try {
        // Create fresh environment for each iteration
        auto env = createFuzzerEnv();

        // Create OpenView from current ledger
        ripple::OpenView ov{*env->current()};

        // Create dummy escrow keylet for WASM context
        auto const dummyEscrow = ripple::keylet::escrow(
            env->master,
            env->seq(env->master)
        );

        // Create ApplyContext
        auto ac = createFuzzerApplyContext(*env, ov);

        // Create WasmHostFunctionsImpl with real ledger access
        ripple::WasmHostFunctionsImpl hfs(ac, dummyEscrow);

        // Convert fuzzer input to WASM bytecode
        std::vector<uint8_t> wasm(ptr, ptr + size);

        // Create import vector
        ripple::ImportVec imp = createWasmImport(hfs);

        // Set limited gas for fuzzing
        for (auto& i : imp) {
            i.second.gas = 1000;
        }

        // Run WASM with realistic host function implementation
        auto& engine = ripple::WasmEngine::instance();
        auto re = engine.run(
            wasm,
            "finish",
            {},
            imp,
            &hfs,
            100'000,  // Instruction limit
            env->journal
        );

    } catch (...) {
        // Catch exceptions to prevent fuzzer from stopping
    }

    return 0;
}
