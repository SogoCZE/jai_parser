#import "Basic";

SHADER :: #string _GLSL
    in vec3 fromPrevious;
    in uvec2 fromRange;

    const int foo = 5;
    const uvec2 range = uvec2(2, 5);
    uniform vec2 pairs;

    uniform sampler2d tex;

    void main()
    {
    foo; // constant expressions are dynamically uniform.

    uint value = 21; // 'value' is dynamically uniform.
    value = range.x; // still dynamically uniform.
    value = range.y + fromRange.y; // not dynamically uniform; current contents come from a non-dynamically uniform source.
    value = 4; // dynamically uniform again.
    if (fromPrevious.y < 3.14)
        value = 12;
    value; // NOT dynamically uniform. Current contents depend on 'fromPrevious', an input variable.

    float number = abs(pairs.x); // 'number' is dynamically uniform.
    number = sin(pairs.y); // still dynamically uniform.
    number = cos(fromPrevious.x); // not dynamically uniform.

    vec4 colors = texture(tex, pairs.xy); // dynamically uniform, even though it comes from a texture.
                                            // It uses the same texture coordinate, thus getting the same texel every time.
    colors = texture(tex, fromPrevious.xy); // not dynamically uniform.

    for(int i = range.x; i < range.y; ++i)
    {
        // loop initialized with, compared against, and incremented by dynamically uniform expressions.
        i; // Therefore, 'i' is dynamically uniform, even though it changes.
    }

    for(int i = fromRange.x; i < fromRange.y; ++i)
    {
        i; // 'i' is not dynamically uniform; 'fromRange' is not dynamically uniform.
    }
    }
_GLSL;

TEST :: 10;

main :: () {
    print("Hello World!\n");
}

