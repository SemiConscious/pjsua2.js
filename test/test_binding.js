const Pjsua2Js = require("../dist/binding.js");
const assert = require("assert");

assert(Pjsua2Js, "The expected function is undefined");

function testBasic()
{
    const result =  Pjsua2Js("hello");
    assert.strictEqual(result, "world", "Unexpected value returned");
}

assert.doesNotThrow(testBasic, undefined, "testBasic threw an expection");

console.log("Tests passed- everything looks OK!");