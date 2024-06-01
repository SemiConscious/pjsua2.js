#ifndef __VIDEOMEDIAPORT_HPP__
#define __VIDEOMEDIAPORT_HPP__

// missing VideoMediaPort implementation

#include <pjsua-lib/pjsua.h>
#include <pjsua2/types.hpp>
#include <pjsua2/media.hpp>

using namespace pj;
using namespace std;

#include <pjsua-lib/pjsua_internal.h>

#define THIS_FILE "videomediaport.hpp"


namespace pj
{
    class VideoMediaPort: public VideoMedia {

        public:

        VideoMediaPort()
        : pool(NULL)
        {
            pj_bzero(&port, sizeof(port));
        }

        virtual ~VideoMediaPort()
        {
            if (pool) {
                PJSUA2_CATCH_IGNORE( unregisterMediaPort() );
                pj_pool_release(pool);
                pool = NULL;
            }
        }

        static pj_status_t get_frame(pjmedia_port *port, pjmedia_frame *frame)
        {
            VideoMediaPort *mport = (VideoMediaPort *) port->port_data.pdata;
            MediaFrame frame_;

            frame_.size = frame->size;
            mport->onFrameRequested(frame_);
            frame->type = frame_.type;
            frame->size = PJ_MIN(frame_.buf.size(), frame_.size);

        #if ((defined(_MSVC_LANG) && _MSVC_LANG <= 199711L) || __cplusplus <= 199711L)
            /* C++98 does not have Vector::data() */
            if (frame->size > 0)
                pj_memcpy(frame->buf, &frame_.buf[0], frame->size);
        #else
            /* Newer than C++98 */
            pj_memcpy(frame->buf, frame_.buf.data(), frame->size);
        #endif


            return PJ_SUCCESS;
        }

        static pj_status_t put_frame(pjmedia_port *port, pjmedia_frame *frame)
        {
            VideoMediaPort *mport = (VideoMediaPort *) port->port_data.pdata;
            MediaFrame frame_;

            frame_.type = frame->type;
            frame_.buf.assign((char *)frame->buf, ((char *)frame->buf) + frame->size);
            frame_.size = frame->size;
            mport->onFrameReceived(frame_);

            return PJ_SUCCESS;
        }

        void createPort(const string &name, MediaFormatVideo &fmt)
                                        PJSUA2_THROW(Error)
        {
            pj_str_t name_;
            pjmedia_format fmt_;

            if (pool) {
                PJSUA2_RAISE_ERROR(PJ_EEXISTS);
            }

            pool = pjsua_pool_create( "vmport%p", 512, 512);
            if (!pool) {
                PJSUA2_RAISE_ERROR(PJ_ENOMEM);
            }

            /* Init port. */
            pj_bzero(&port, sizeof(port));
            pj_strdup2_with_null(pool, &name_, name.c_str());
            fmt_ = fmt.toPj();
            pjmedia_port_info_init2(&port.info, &name_,
                                    PJMEDIA_SIG_CLASS_APP ('V', 'M', 'P'),
                                    PJMEDIA_DIR_ENCODING_DECODING, &fmt_);

            port.port_data.pdata = this;
            port.put_frame = &put_frame;
            port.get_frame = &get_frame;

            registerMediaPort(&port, pool);
        }

        /*
        * Callbacks
        */
        /**
         * This callback is called to request a frame from this port. On input,
         * frame.size indicates the capacity of the frame buffer and frame.buf
         * will initially be an empty vector. Application can then set the frame
         * type and fill the vector.
         *
         * @param frame       The frame.
         */
        virtual void onFrameRequested(MediaFrame &frame)
        { PJ_UNUSED_ARG(frame); }

        /**
         * This callback is called when this port receives a frame. The frame
         * content will be provided in frame.buf vector, and the frame size
         * can be found in either frame.size or the vector's size (both
         * have the same value).
         *
         * @param frame       The frame.
         */
        virtual void onFrameReceived(MediaFrame &frame)
        { PJ_UNUSED_ARG(frame); }

    private:
        pj_pool_t *pool;
        pjmedia_port port;
    };
}

#endif