// adapted from shader toy

// OKLAB HAS 3 PARTS
// x is luminance 0 is black, 1 is white
// y for green (negative) to red (positive)
// z for blue (negative) to yellow (positive)


// By Björn Ottosson
// https://bottosson.github.io/posts/oklab
// Shader functions adapted by "mattz"
// https://www.shadertoy.com/view/WtccD7
vec3 oklab_from_linear(vec3 linear) {
    const mat3 im1 = mat3(vec3(0.4121656120, 0.2118591070, 0.0883097947),
                          vec3(0.5362752080, 0.6807189584, 0.2818474174),
                          vec3(0.0514575653, 0.1074065790, 0.6302613616)
						);

    const mat3 im2 = mat3(vec3(+0.2104542553, +1.9779984951, +0.0259040371),
                          vec3(+0.7936177850, -2.4285922050, +0.7827717662),
                          vec3(-0.0040720468, +0.4505937099, -0.8086757660)
						);

    vec3 lms = im1 * linear;

    return im2 * (sign(lms) * pow(abs(lms), vec3(1.0/3.0)));
}

vec3 linear_from_oklab(vec3 oklab) {
    const mat3 m1 = mat3(vec3(+1.000000000, +1.000000000, +1.000000000),
                         vec3(+0.396337777, -0.105561346, -0.089484178),
                         vec3(+0.215803757, -0.063854173, -1.291485548)
						);

    const mat3 m2 = mat3(vec3(+4.076724529, -1.268143773, -0.004111989),
                         vec3(-3.307216883, +2.609332323, -0.703476310),
                         vec3(+0.230759054, -0.341134429, +1.706862569)
						);
    vec3 lms = m1 * oklab;

    return m2 * (lms * lms * lms);
}


// really would rather be in oklch
// https://bottosson.github.io/posts/oklab/
vec3 oklch_from_oklab(vec3 v) {
	float c_ = length(v.yz);
	float h_ = atan(v.z, v.y);
	return vec3(v.x, c_, h_);
}

vec3 oklab_from_oklch(vec3 v) {
	float a_ = v.y * cos(v.z);
	float b_ = v.y * sin(v.z);
	return vec3(v.x, a_, b_);
}



// heavily adapted from stack overflow post
// https://gamedev.stackexchange.com/questions/92015/optimized-linear-to-srgb-glsl
// Converts a color from linear light gamma to sRGB gamma
vec3 sRGB_from_linear(vec3 linearRGB) {
    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB.rgb * vec3(12.92);

    return mix(higher, lower, cutoff);
}

// Converts a color from sRGB gamma to linear light gamma
vec3 linear_from_sRGB(vec3 sRGB) {
    bvec3 cutoff = lessThan(sRGB.rgb, vec3(0.04045));
    vec3 higher = pow((sRGB.rgb + vec3(0.055))/vec3(1.055), vec3(2.4));
    vec3 lower = sRGB.rgb/vec3(12.92);

    return mix(higher, lower, cutoff);
}
