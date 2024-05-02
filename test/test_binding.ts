// this is an implementation of the 'hello world' pjsua2 app here:
// `https://docs.pjsip.org/en/latest/pjsua2/hello_world.html`

// the c++ app has 'use namespace pj' which we could model by doing
// `import * from '../dist/binding.js` but that seems a bit inefficient

// ES2020 encourages us to use import

import {
    Endpoint,
    EpConfig,
    TransportConfig,
    PJSIP_TRANSPORT_UDP,
    AccountConfig,
    AuthCredInfo,
    AuthCredInfoVector,
    Account,
    AccountInfo,
    OnRegStateParam
} from "../dist/binding.js"

const assert = require("assert")

// Subclass to extend the Account and get notifications etc.
class MyAccount extends Account {
    public onRegState = (prm: OnRegStateParam): void => {
        const ai: AccountInfo = this.getInfo();
        console.log(ai.regIsActive ? "*** Register:" : "*** Unregister:" + " code=" + prm.code)
    }
};

// place top level C++ code in an async function so we can use a promise
// for the delay function and exceptions still work

async function testBasic() {

    const ep = new Endpoint();

    ep.libCreate();

    // Initialize endpoint
    const ep_cfg = new EpConfig();
    console.log(ep_cfg)
    ep.libInit(ep_cfg);

    // Create SIP transport. Error handling sample is shown
    const tcfg = new TransportConfig();
    tcfg.port = 5060;
    try {
        ep.transportCreate(PJSIP_TRANSPORT_UDP, tcfg);
    } catch (err: any) {
        console.log(err.info());
        return 1;
    }

    // Start the library (worker threads etc)
    ep.libStart();
    console.log("*** PJSUA2 STARTED ***");

    // Configure an AccountConfig
    const acfg = new AccountConfig();
    acfg.idUri = "sip:test@sip.pjsip.org";
    acfg.regConfig.registrarUri = "sip:sip.pjsip.org";
    const cred = new AuthCredInfo("digest", "*", "test", 0, "secret");
    acfg.sipConfig.authCreds = new AuthCredInfoVector()
    acfg.sipConfig.authCreds.add(cred)

    // Create the account
    let acc: MyAccount | null = new MyAccount()
    acc.create(acfg);

    // Here we don't have anything else to do..
    await new Promise((resolve) => { setTimeout(() => resolve(true), 10000) })

    // Delete the account. This will unregister from server
    acc = null
    // assert.strictEqual(result, "world", "Unexpected value returned");
}

async function runTests() {

    assert(Endpoint, "the binding is null");

    try {
        await testBasic()
    } catch (err) {
        assert(true, "testBasic threw an expection");
    }

    console.log("Tests passed- everything looks OK!");
}

runTests()
