// macros that help with extending the callback classes
#define CB_PASTE2(a,b) a ## b
#define CB_PASTE3(a,b,c) a ## b ## c
#define CB_PASTE4(a,b,c,d) a ## b ## c ## d
#define CB_PASTE6(a,b,c,d,e,f) a ## b ## c ## d ## e ## f
#define CB_PASTE7(a,b,c,d,e,f,g) a ## b ## c ## d ## e ## f ## g
#define CB_PASTE8(a,b,c,d,e,f,g,h) a ## b ## c ## d ## e ## f ## g ## h
#define CB_PTYPE(fun) On ## fun ## Param
#define CB_SETFUNC(cls,fun) cls ## ::on ## fun ## CB

%define CB_IGNORE_PARENT(cls,fun)
// ignore parent overridable callback fn
%ignore CB_PASTE2("on",#fun);
%enddef

// AccountCB

CB_IGNORE_PARENT(Account, IncomingCall)
CB_IGNORE_PARENT(Account, RegStarted)
CB_IGNORE_PARENT(Account, RegState)
CB_IGNORE_PARENT(Account, IncomingSubscribe)
CB_IGNORE_PARENT(Account, InstantMessage)
CB_IGNORE_PARENT(Account, InstantMessageStatus)
CB_IGNORE_PARENT(Account, TypingIndication)
CB_IGNORE_PARENT(Account, MwiInfo)

// EndpointCB

CB_IGNORE_PARENT(Endpoint, NatDetectionComplete)
CB_IGNORE_PARENT(Endpoint, NatCheckStunServersComplete)
CB_IGNORE_PARENT(Endpoint, TransportState)
CB_IGNORE_PARENT(Endpoint, Timer)
CB_IGNORE_PARENT(Endpoint, SelectAccount)
CB_IGNORE_PARENT(Endpoint, IpChangeProgress)
CB_IGNORE_PARENT(Endpoint, MediaEvent)
CB_IGNORE_PARENT(Endpoint, CredAuth)
CB_IGNORE_PARENT(Endpoint, RejectedIncomingCall)

// CallCB

CB_IGNORE_PARENT(Call, CallState)
CB_IGNORE_PARENT(Call, CallTsxState)
CB_IGNORE_PARENT(Call, CallMediaState)
CB_IGNORE_PARENT(Call, CallSdpCreated)
CB_IGNORE_PARENT(Call, StreamPreCreate)
CB_IGNORE_PARENT(Call, StreamCreated)
CB_IGNORE_PARENT(Call, StreamDestroyed)
CB_IGNORE_PARENT(Call, DtmfDigit)
CB_IGNORE_PARENT(Call, DtmfEvent)
CB_IGNORE_PARENT(Call, CallTransferRequest)
CB_IGNORE_PARENT(Call, CallTransferStatus)
CB_IGNORE_PARENT(Call, CallReplaceRequest)
CB_IGNORE_PARENT(Call, CallReplaced)
CB_IGNORE_PARENT(Call, CallRxOffer)
CB_IGNORE_PARENT(Call, CallRxReinvite)
CB_IGNORE_PARENT(Call, CallTxOffer)
CB_IGNORE_PARENT(Call, InstantMessage)
CB_IGNORE_PARENT(Call, InstantMessageStatus)
CB_IGNORE_PARENT(Call, TypingIndication)
CB_IGNORE_PARENT(Call, CallRedirected)
CB_IGNORE_PARENT(Call, CallMediaTransportState)
CB_IGNORE_PARENT(Call, CallMediaEvent)
CB_IGNORE_PARENT(Call, CreateMediaTransport)
CB_IGNORE_PARENT(Call, CreateMediaTransportSrtp)

// AudioMediaPortCB

CB_IGNORE_PARENT(AudioMediaPort, FrameRequested)
CB_IGNORE_PARENT(AudioMediaPort, FrameReceived)

// AudioMediaPlayerCB

CB_IGNORE_PARENT(AudioMediaPlayer, Eof2)

// BuddyCB

CB_IGNORE_PARENT(Buddy, BuddyState)
CB_IGNORE_PARENT(Buddy, BuddyEvSubState)

%{
  #include <set>
  #include <condition_variable>

  // assumption - we are effectively single threaded so there should never
  // be more than one thread accessing a handler at once. Eg: when a callback
  // is invoked, its handler is installed. When a call into the library happens
  // during the callback, the JS thread invokes the PJSUA2 thread and locks until
  // this function returns.

  enum mywrap_op {
    waiting,
    job_ready,
    returned
  };

  class mywrap_handler {
    private:
      std::mutex &m;
      std::condition_variable &cv;
      mywrap_op &op;
      std::function<void()> fn;
    public:
      mywrap_handler(std::mutex &m, std::condition_variable &cv, mywrap_op &op) : m(m), cv(cv), op(op)  {}

      void run_function() {
        fn();
      }

      void run_job(std::function<void(void)> thefn) {
        {
          std::lock_guard lk(m);
          fn = thefn;
          op = job_ready;
        }

        // notify the worker we have one ready
        cv.notify_one();
        
        {
          std::unique_lock lock(m);
          cv.wait(lock, [&op=this->op]{ 
            return op == waiting; 
          });
        }
      }
  };

  std::mutex mywrap_mutex;
  std::set<mywrap_handler *> mywrap_handlers;

  void mywrap_push_handler(mywrap_handler *handler) {
    std::lock_guard lk(mywrap_mutex);
    mywrap_handlers.insert(handler);
  }

  void mywrap_pop_handler(mywrap_handler *handler) {
    std::lock_guard lk(mywrap_mutex);
    mywrap_handlers.erase(handler);
  }

  void mywrap_call(std::function<void(void)> fn) { 
    std::unique_lock lk(mywrap_mutex);
    if (!mywrap_handlers.empty()) {
      mywrap_handler *handler = *(mywrap_handlers.begin());
      handler->run_job(fn); 
    } else {
      lk.unlock();
      fn();
    }
  }
%}

%include "../build/pjproject/pjsip-apps/src/swig/pjsua2.i"

%{
#include "videomediaport.hpp"
#include "callback.hpp"

#define ASYNC_CALLBACK_SUPPORT
%}

#define ASYNC_CALLBACK_SUPPORT
%include <swig_napi_callback.i>

// handle functions with void return and one argument
%define CB_TYPEMAP(ParamType)
%typemap(in, fragment="SWIG_NAPI_Callback") std::function<void(ParamType &)> {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  $1 = SWIG_NAPI_Callback<void, ParamType &>(
    $input,
    std::function<void(Napi::Env, std::vector<napi_value> &, ParamType &)>(
      [](Napi::Env env, std::vector<napi_value> &js_args, ParamType &Param) -> void {
        $typemap(out, ParamType, 1=Param, result=js_args.at(0), argnum=callback argument 1);
      }
    ),
    [](Napi::Env env, Napi::Value js_ret) -> std::function<void(void)> {
      return []() -> void {};
    },
    [](Napi::Env env, Napi::Function js_callback, const std::vector<napi_value> &js_args) -> Napi::Value {
      return js_callback.Call(env.Undefined(), js_args);
    }
  );
}
%enddef

// handle functions with non-void return and one argument
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
    [&](Napi::Env env, Napi::Value js_ret) -> std::function<ReturnType(void)> {
      ReturnType c_ret;
      $typemap(in, ReturnType, input=js_ret, 1=c_ret, argnum=JavaScript callback return value)
      return [c_ret]() -> ReturnType { return c_ret; };
    },
    [](Napi::Env env, Napi::Function js_callback, const std::vector<napi_value> &js_args) -> Napi::Value {
      return js_callback.Call(env.Undefined(), js_args);
    }
  );
}
%enddef

// handle functions with void return and no arguments
%define CB_TYPEMAP_VOID
%typemap(in, fragment="SWIG_NAPI_Callback") std::function<void(void)> {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  $1 = SWIG_NAPI_Callback<void>(
    $input,
    std::function<void(Napi::Env, std::vector<napi_value> &)>(
      [](Napi::Env env, std::vector<napi_value> &js_args) -> void {}
    ),
    [](Napi::Env env, Napi::Value js_ret) -> std::function<void(void)> {
      return []() -> void {};
    },
    [](Napi::Env env, Napi::Function js_callback, const std::vector<napi_value> &js_args) -> Napi::Value {
      return js_callback.Call(env.Undefined(), js_args);
    }
  );
}
%enddef

// call this with the parent class name (eg Account, not AccountCB)
%define CB_MANAGE_INNER(cls,fun,ret,cpparg,tsarg)
// ignore CB function member and overridden callback
%ignore CB_PASTE3(cls,CB::on,fun);
%ignore CB_PASTE4(cls,CB::on,fun,CBFn);
%typemap(ts) std::function<ret(cpparg)> fn CB_PASTE6("(",#tsarg,") => Promise<",#ret,"> | ",#ret);
%enddef

%define CB_MANAGE(cls,fun)
CB_MANAGE_INNER(cls,fun,void,On ## fun ## Param ## &,prm: On ## fun ## Param)
%enddef

%define CB_MANAGE_RET(cls,fun,ret)
CB_MANAGE_INNER(cls,fun,ret,On ## fun ## Param ## &,prm: On ## fun ## Param)
%enddef

%define CB_MANAGE_VOID(cls,fun)
CB_MANAGE_INNER(cls,fun,void,void,)
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
CB_MANAGE_RET(Endpoint, CredAuth, pj_status_t)
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
CB_MANAGE_RET(Call, CallRedirected, pjsip_redirect_op)
CB_MANAGE(Call, CallMediaTransportState)
CB_MANAGE(Call, CallMediaEvent)
CB_MANAGE(Call, CreateMediaTransport)
CB_MANAGE(Call, CreateMediaTransportSrtp)

// AudioMediaPortCB

CB_TYPEMAP(MediaFrame)
CB_TYPEMAP_RET(MediaFrame, MediaFrame)
CB_MANAGE_INNER(AudioMediaPort, FrameRequested, MediaFrame, MediaFrame&, prm: MediaFrame)
CB_MANAGE_INNER(AudioMediaPort, FrameReceived, void, MediaFrame&, prm: MediaFrame)

// VideoMediaPortCB

// CB_TYPEMAP(MediaFrame)
// CB_TYPEMAP_RET(MediaFrame, MediaFrame)
CB_MANAGE_INNER(VideoMediaPort, FrameRequested, MediaFrame, MediaFrame&, prm: MediaFrame)
CB_MANAGE_INNER(VideoMediaPort, FrameReceived, void, MediaFrame&, prm: MediaFrame)

// AudioMediaPlayerCB

CB_TYPEMAP_VOID
CB_MANAGE_VOID(AudioMediaPlayer, Eof2)

// BuddyCB

//CB_TYPEMAP_VOID // only one of these needed
CB_TYPEMAP(CB_PTYPE(BuddyEvSubState))

CB_MANAGE_VOID(Buddy, BuddyState)
CB_MANAGE(Buddy, BuddyEvSubState)

%include "videomediaport.hpp"
%include "callback.hpp"

