%include "../build/pjproject/pjsip-apps/src/swig/pjsua2.i"

%{
#include "callback.hpp"
#include <thread>

typedef size_t CBContext;

template<typename PARAM, void (*PARAMBUILDER)(Napi::Env, PARAM *, std::vector<napi_value> &)>
std::function<void(PARAM &)> DoTypemap(Napi::Env env, Napi::Function js_callback) {
  const auto JSCall = [](Napi::Env env, Napi::Function callback, CBContext *ctx, PARAM *data) {
    if (ctx != 0) {
      if (env != nullptr) {
        if (callback != nullptr) {
          std::vector<napi_value> js_args;
          PARAMBUILDER(env, data, js_args);
          callback.Call(js_args.size(), js_args.data());
        }
      }
      delete data;
    } // else called with null ctx on shutdown
  };

  CBContext *ctx = new CBContext(1);
  using TSFN = Napi::TypedThreadSafeFunction<CBContext, PARAM, JSCall>;

  TSFN tsfn = TSFN::New(env, js_callback, "Param", 0, 1, ctx, [](Napi::Env, void *, CBContext *ctx) { delete ctx; });

  // $1 is what we pass to the C++ function -> it is a C++ wrapper
  // around the JS callback
  return [=](PARAM &prm) -> void {
    // tsfn.Acquire();
    napi_status status = tsfn.BlockingCall(new PARAM(prm));
    if (status != napi_ok) {
      // Handle error
    }
  };
}

%}

// macro to convert JS function callbacks to C++ function
%define CB_TYPEMAP(ParamType)
%typemap(in) std::function<void(ParamType &)> {
  const auto ParamBuilder = [](Napi::Env env, ParamType *data, std::vector<napi_value> &js_args) -> void {
    js_args = {napi_value{}};
    $typemap(out, ParamType, 1=*((ParamType *)data), result=js_args.at(0), argnum=callback argument 1);
  };
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  $1 = DoTypemap<ParamType, ParamBuilder>(env, $input.As<Napi::Function>());
}
%enddef

// macros that help with extending the callback classes
#define CB_PASTE2(a,b) a ## b
#define CB_PASTE3(a,b,c) a ## b ## c
#define CB_PTYPE(fun) On ## fun ## Param

%define CB_MANAGE(cls,fun)
%ignore CB_PASTE2(cls::on,fun);
%ignore CB_PASTE3(cls::on,fun,CBFn);
%enddef

// AccountCB typemaps (before header)
CB_TYPEMAP(CB_PTYPE(IncomingCall))
CB_TYPEMAP(CB_PTYPE(RegStarted))
CB_TYPEMAP(CB_PTYPE(RegState))
CB_TYPEMAP(CB_PTYPE(IncomingSubscribe))
CB_TYPEMAP(CB_PTYPE(InstantMessage))
CB_TYPEMAP(CB_PTYPE(InstantMessageStatus))
CB_TYPEMAP(CB_PTYPE(TypingIndication))
CB_TYPEMAP(CB_PTYPE(MwiInfo))

CB_MANAGE(AccountCB, IncomingCall)
CB_MANAGE(AccountCB, RegStarted)
CB_MANAGE(AccountCB, RegState)
CB_MANAGE(AccountCB, IncomingSubscribe)
CB_MANAGE(AccountCB, InstantMessage)
CB_MANAGE(AccountCB, InstantMessageStatus)
CB_MANAGE(AccountCB, TypingIndication)
CB_MANAGE(AccountCB, MwiInfo)

%include "callback.hpp"

