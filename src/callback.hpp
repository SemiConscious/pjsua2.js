#ifndef __CALLBACK_HPP__
#define __CALLBACK_HPP__

#include "pjsua2.hpp"
using namespace pj;

#define CB_TYPE(fun) std::function<void(On ## fun ## Param &)>
#define CB_IMPL(fun) CB_TYPE(fun) on ## fun ## CBFn; \
void set ## fun ## CB(CB_TYPE(fun) fn) { on ## fun ## CBFn = fn; } \
virtual void on ## fun(On ## fun ## Param &prm) { if (on ## fun ## CBFn) { on ## fun ##CBFn(prm); } }
#define DESTRUCT(fun) if (on ## fun ## CBFn) { on ## fun ## CBFn = nullptr; on ## fun ## CBFn = 0; }

class AccountCB: public Account {
    public:
    void destroy() {
        DESTRUCT(IncomingCall)
        DESTRUCT(RegStarted)
        DESTRUCT(RegState)
        DESTRUCT(IncomingSubscribe)
        DESTRUCT(InstantMessage)
        DESTRUCT(InstantMessageStatus)
        DESTRUCT(TypingIndication)
        DESTRUCT(MwiInfo)
    }
    ~AccountCB() {
        destroy();
    }
    CB_IMPL(IncomingCall)
    CB_IMPL(RegStarted)
    CB_IMPL(RegState)
    CB_IMPL(IncomingSubscribe)
    CB_IMPL(InstantMessage)
    CB_IMPL(InstantMessageStatus)
    CB_IMPL(TypingIndication)
    CB_IMPL(MwiInfo)
};

#endif