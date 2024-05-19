%include "../build/pjproject/pjsip-apps/src/swig/pjsua2.i"

%{
#include "callback.hpp"

#define ASYNC_CALLBACK_SUPPORT

typedef Napi::Reference<Napi::Value> CBContext;
%}

#define ASYNC_CALLBACK_SUPPORT
%include <swig_napi_callback.i>

%define CB_TYPEMAP(ParamType)
%typemap(in, fragment="SWIG_NAPI_Callback_Void") std::function<void(ParamType &)> {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  $1 = SWIG_NAPI_Callback_Void<ParamType &>(
    $input,
    std::function<void(Napi::Env, std::vector<napi_value> &, ParamType &)>(
      [](Napi::Env env, std::vector<napi_value> &js_args, ParamType &Param) -> void {
        $typemap(out, ParamType, 1=Param, result=js_args.at(0), argnum=callback argument 1);
      }
    ),
    [](Napi::Env env, Napi::Function js_callback, const std::vector<napi_value> &js_args) -> Napi::Value {
      return js_callback.Call(env.Undefined(), js_args);
    }
  );
}
%enddef

%define CB_TYPEMAP_RET(ParamType, ReturnType)
%typemap(in, fragment="SWIG_NAPI_Callback") std::function<ReturnType(ParamType &)> {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  $1 = SWIG_NAPI_Callback<ReturnType, ParamType &>(
    $input,
    std::function<void(Napi::Env, std::vector<napi_value> &, ParamType &)>(
      [](Napi::Env env, std::vector<napi_value> &js_args, ParamType &Param) -> void {
        $typemap(out, ParamType, 1=Param, result=js_args.at(0), argnum=callback argument 1);
      }
    ),
    [&ecode1, &val1](Napi::Env env, Napi::Value js_ret) -> ReturnType {
      ReturnType c_ret;
      $typemap(in, ReturnType, input=js_ret, 1=c_ret, argnum=JavaScript callback return value)
      return c_ret;
    },
    [](Napi::Env env, Napi::Function js_callback, const std::vector<napi_value> &js_args) -> Napi::Value {
      return js_callback.Call(env.Undefined(), js_args);
    }
  );
}
%enddef

%define CB_TYPEMAP_VOID
%typemap(in, fragment="SWIG_NAPI_Callback_Void") std::function<void(void)> {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  $1 = SWIG_NAPI_Callback_Void<>(
    $input,
    std::function<void(Napi::Env, std::vector<napi_value> &)>(
      [](Napi::Env env, std::vector<napi_value> &js_args) -> void {}
    ),
    [](Napi::Env env, Napi::Function js_callback, const std::vector<napi_value> &js_args) -> Napi::Value {
      return js_callback.Call(env.Undefined(), js_args);
    }
  );
}
%enddef

// macros that help with extending the callback classes
#define CB_PASTE2(a,b) a ## b
#define CB_PASTE3(a,b,c) a ## b ## c
#define CB_PASTE4(a,b,c,d) a ## b ## c ## d
#define CB_PTYPE(fun) On ## fun ## Param

// call this with the parent class name (eg Account, not AccountCB)
%define CB_MANAGE(cls,fun)
// ignore CB function member and overridden callback
%ignore CB_PASTE3(cls,CB::on,fun);
%ignore CB_PASTE4(cls,CB::on,fun,CBFn);
// ignore parent overridable callback fn
%ignore CB_PASTE3(cls,::on,fun);
%enddef

// AccountCB

CB_TYPEMAP(CB_PTYPE(IncomingCall))
CB_TYPEMAP(CB_PTYPE(RegStarted))
CB_TYPEMAP(CB_PTYPE(RegState))
CB_TYPEMAP(CB_PTYPE(IncomingSubscribe))
CB_TYPEMAP(CB_PTYPE(InstantMessage))
CB_TYPEMAP(CB_PTYPE(InstantMessageStatus))
CB_TYPEMAP(CB_PTYPE(TypingIndication))
CB_TYPEMAP(CB_PTYPE(MwiInfo))

CB_MANAGE(Account, IncomingCall)
CB_MANAGE(Account, RegStarted)
CB_MANAGE(Account, RegState)
CB_MANAGE(Account, IncomingSubscribe)
CB_MANAGE(Account, InstantMessage)
CB_MANAGE(Account, InstantMessageStatus)
CB_MANAGE(Account, TypingIndication)
CB_MANAGE(Account, MwiInfo)

// EndpointCB

CB_TYPEMAP(CB_PTYPE(NatDetectionComplete))
CB_TYPEMAP(CB_PTYPE(NatCheckStunServersComplete))
CB_TYPEMAP(CB_PTYPE(TransportState))
CB_TYPEMAP(CB_PTYPE(Timer))
CB_TYPEMAP(CB_PTYPE(SelectAccount))
CB_TYPEMAP(CB_PTYPE(IpChangeProgress))
CB_TYPEMAP(CB_PTYPE(MediaEvent))
CB_TYPEMAP_RET(CB_PTYPE(CredAuth), pj_status_t)
CB_TYPEMAP(CB_PTYPE(RejectedIncomingCall))

CB_MANAGE(Endpoint, NatDetectionComplete)
CB_MANAGE(Endpoint, NatCheckStunServersComplete)
CB_MANAGE(Endpoint, TransportState)
CB_MANAGE(Endpoint, Timer)
CB_MANAGE(Endpoint, SelectAccount)
CB_MANAGE(Endpoint, IpChangeProgress)
CB_MANAGE(Endpoint, MediaEvent)
CB_MANAGE(Endpoint, CredAuth)
CB_MANAGE(Endpoint, RejectedIncomingCall)

// CallCB

CB_TYPEMAP(CB_PTYPE(CallState))
CB_TYPEMAP(CB_PTYPE(CallTsxState))
CB_TYPEMAP(CB_PTYPE(CallMediaState))
CB_TYPEMAP(CB_PTYPE(CallSdpCreated))
CB_TYPEMAP(CB_PTYPE(StreamPreCreate))
CB_TYPEMAP(CB_PTYPE(StreamCreated))
CB_TYPEMAP(CB_PTYPE(StreamDestroyed))
CB_TYPEMAP(CB_PTYPE(DtmfDigit))
CB_TYPEMAP(CB_PTYPE(DtmfEvent))
CB_TYPEMAP(CB_PTYPE(CallTransferRequest))
CB_TYPEMAP(CB_PTYPE(CallTransferStatus))
CB_TYPEMAP(CB_PTYPE(CallReplaceRequest))
CB_TYPEMAP(CB_PTYPE(CallReplaced))
CB_TYPEMAP(CB_PTYPE(CallRxOffer))
CB_TYPEMAP(CB_PTYPE(CallRxReinvite))
CB_TYPEMAP(CB_PTYPE(CallTxOffer))
CB_TYPEMAP(CB_PTYPE(InstantMessage))
CB_TYPEMAP(CB_PTYPE(InstantMessageStatus))
CB_TYPEMAP(CB_PTYPE(TypingIndication))
CB_TYPEMAP_RET(CB_PTYPE(CallRedirected), pjsip_redirect_op)
CB_TYPEMAP(CB_PTYPE(CallMediaTransportState))
CB_TYPEMAP(CB_PTYPE(CallMediaEvent))
CB_TYPEMAP(CB_PTYPE(CreateMediaTransport))
CB_TYPEMAP(CB_PTYPE(CreateMediaTransportSrtp))

CB_MANAGE(Call, CallState)
CB_MANAGE(Call, CallTsxState)
CB_MANAGE(Call, CallMediaState)
CB_MANAGE(Call, CallSdpCreated)
CB_MANAGE(Call, StreamPreCreate)
CB_MANAGE(Call, StreamCreated)
CB_MANAGE(Call, StreamDestroyed)
CB_MANAGE(Call, DtmfDigit)
CB_MANAGE(Call, DtmfEvent)
CB_MANAGE(Call, CallTransferRequest)
CB_MANAGE(Call, CallTransferStatus)
CB_MANAGE(Call, CallReplaceRequest)
CB_MANAGE(Call, CallReplaced)
CB_MANAGE(Call, CallRxOffer)
CB_MANAGE(Call, CallRxReinvite)
CB_MANAGE(Call, CallTxOffer)
CB_MANAGE(Call, InstantMessage)
CB_MANAGE(Call, InstantMessageStatus)
CB_MANAGE(Call, TypingIndication)
CB_MANAGE(Call, CallRedirected)
CB_MANAGE(Call, CallMediaTransportState)
CB_MANAGE(Call, CallMediaEvent)
CB_MANAGE(Call, CreateMediaTransport)
CB_MANAGE(Call, CreateMediaTransportSrtp)

// AudioMediaPortCB

CB_TYPEMAP(MediaFrame)
CB_MANAGE(AudioMediaPort, FrameRequested)
CB_MANAGE(AudioMediaPort, FrameReceived)

// AudioMediaPlayerCB

CB_TYPEMAP_VOID
CB_MANAGE(AudioMediaPlayer, Eof2)

// BuddyCB

//CB_TYPEMAP_VOID // only one of these needed
CB_TYPEMAP(CB_PTYPE(BuddyEvSubState))

CB_MANAGE(Buddy, BuddyState)
CB_MANAGE(Buddy, BuddyEvSubState)

%include "callback.hpp"

