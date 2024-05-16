{
  'variables': {
      'arch%': '<!(uname -m)'
  },
  'targets': [
    {
      'target_name': 'build-pjsua',
      'type': 'none',
      'actions': [
        {
          'action_name': 'git-clone-pjsip',
          'message': 'getting pjsip sources from github',
          'action': ['git', 'clone', 'https://github.com/pjsip/pjproject', 'build/pjproject'],
          'inputs': ['package.json'],
          'outputs': ['build/pjproject']
        },
        {
          'action_name': 'build',
          'message': 'building pjsua2 and bindings',
          'action': ['src/build.sh'],
          'inputs': ['build/pjproject'],
          'outputs': ['build/swig/pjsua2_wrap.cpp']
        }
      ]
    },
    {
      'target_name': 'pjsua2',
      'sources': [ 'build/swig/pjsua2_wrap.cpp' ],
      'include_dirs': [
        "<!@(node -p \"require('node-addon-api').include\")",
        "build/usr/include",
        "src"
      ],
      'link_settings': {
        'library_dirs': [
          "../build/usr/lib"
        ]
      },
      'libraries': [
        # I want to do this but node-gyp tries to evaluate it at the start of the build
        # '>!@(["ls", "-1", "build/usr/lib/pj*.a"])'
        "-lpjsua2",
        "-lpjsua",
        "-lpjsip-ua",
        "-lpjsip-simple",
        "-lpjsip",
        "-lpjmedia-codec",
        "-lpjmedia-videodev",
        "-lpjmedia-audiodev",
        "-lpjmedia",
        "-lpjnath",
        "-lpjlib-util",
        "-lpj",
        "-lsrtp",
        "-lresample",
        "-lgsmcodec",
        "-lspeex",
        "-lilbccodec",
        "-lg7221codec",
        "-lyuv",
        "-lwebrtc",
      ],
      'conditions': [
        [ 'arch=="aarch64" or arch=="arm64"', 
          {
            'defines': [
              'PJ_IS_LITTLE_ENDIAN=1',
              'PJ_IS_BIG_ENDIAN=0'
            ],
          }
        ],
        [ 'OS=="linux"', 
          {
            'libraries': [ 
              "-luuid",
            ]
          }
        ],
        [ 'OS=="mac"', 
          {
            'libraries': [ 
              "-framework CoreAudio",
              "-framework CoreServices",
              "-framework AudioUnit",
              "-framework AudioToolbox",
              "-framework Foundation",
              "-framework AppKit",
              "-framework AVFoundation",
              "-framework CoreGraphics",
              "-framework QuartzCore",
              "-framework CoreVideo",
              "-framework CoreMedia",
              "-framework Metal",
              "-framework MetalKit",
              "-framework VideoToolbox"
            ]
          } 
        ]
      ],
      'dependencies': ["<!(node -p \"require('node-addon-api').gyp\")"],
      'cflags!': [ '-fno-exceptions' ],
      'cflags_cc!': [ '-fno-exceptions' ],
      'cflags': [ '-fPIC' ],
      'cflags_cc': [ '-fexceptions' ],
      'xcode_settings': {
        'GCC_ENABLE_CPP_EXCEPTIONS': 'YES',
        'CLANG_CXX_LIBRARY': 'libc++',
        # 'MACOSX_DEPLOYMENT_TARGET': '10.7'
      },
      'msvs_settings': {
        'VCCLCompilerTool': { 'ExceptionHandling': 1 },
      },
    },{
      'target_name': 'copy-dist-files',
      'dependencies': ['pjsua2'],
      'type': 'none',
      'copies': [{
        'destination': 'dist',
        'files': [
          'build/swig/binding.d.ts',
          'build/binding/binding.js',
          '<(PRODUCT_DIR)/pjsua2.node'
        ]   
      }]
    },
  ]
}