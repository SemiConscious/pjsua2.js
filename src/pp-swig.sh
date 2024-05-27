#/bin/bash

set -ex

# we are in ./pjproject

SED="sed"
if [[ $OSTYPE == 'darwin'* ]]; then
    SED="gsed"
fi

INFILE="../swig/pjsua2_wrap.cpp"
OUTFILE="../swig/pjsua2_wrap_post.cpp"

rm -rf $OUTFILE
cp $INFILE $OUTFILE

#result = (pj_uint8_t) ((arg1)->dscp_val);
$SED -i -E 's/^(\s+)(result = \(([^)]+)\) \(\(arg1\)->([^)]+)\);)/\/\/\2\n\1mywrap_call([\&](){ \2 });/g w /dev/stdout' $OUTFILE

#if (arg1) (arg1)->dscp_val = arg2;
$SED -i -E 's/^(\s+)(if \(arg1\) \(arg1\)->([^ ]+) = arg2;)/\/\/\2\n\1mywrap_call([\&](){ \2 });/g w /dev/stdout' $OUTFILE

# special cases:
# result = (arg1)->getVideoWindow();
#$SED -i -E 's/^(\s+)(result = \(arg1\)->getVideoWindow\(\);)/\1\/\/\2\n\1mywrap_call([\&](){ \2 });/g w /dev/stdout' $OUTFILE

# non void methods
$SED -i -E 's/^(\s+)(result = (\([^(]+\)( &)?)?\((\([^)]+\))?arg1\)->([^(]+)\((((\([^)]+\)\*?)?arg.|SWIG_STD_MOVE\(arg.\)),?)*\);)/\1\/\/\2\n\1mywrap_call([\&](){ \2 });/g w /dev/stdout' $OUTFILE

# void methods
$SED -i -E 's/^(\s+)(\((\([^)]+\))?arg1\)->([^(]+)\((((\([^)]+\)\*?)?arg.|SWIG_STD_MOVE\(arg.\)),?)*\);)/\1\/\/\2\n\1mywrap_call([\&](){ \2 });/g w /dev/stdout' $OUTFILE

# add pj_status_t typedef
$SED -i '1i\export type pj_status_t = number;\n\n' "../swig/binding.d.ts"