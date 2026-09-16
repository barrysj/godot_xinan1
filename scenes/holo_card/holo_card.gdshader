shader_type canvas_item;
render_mode unshaded;
uniform sampler2D photo : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 photo_size = vec2(4.0, 3.0);
uniform vec2 tilt = vec2(0.0);
uniform float foil_strength = 0.7;
uniform float photo_depth = 0.004;
uniform bool effects_enabled = true;
void fragment() {
    vec2 angles = tilt * 0.20944;
    float cx = cos(angles.y), sx = sin(angles.y);
    float cy = cos(angles.x), sy = sin(angles.x);
    mat3 rot = mat3(vec3(cy,0.0,-sy), vec3(sy*sx,cx,cy*sx), vec3(sy*cx,-sx,cy*cx));
    vec3 normal = rot[2];
    vec2 pos = (UV-0.5)*vec2(1.142857,1.0)*1.08;
    vec3 ray = vec3(pos,-2.5);
    float travel = -2.5*normal.z/dot(ray,normal);
    vec3 local = transpose(rot)*(vec3(0.0,0.0,2.5)+travel*ray);
    vec2 uv = local.xy/vec2(1.142857,1.0)+0.5;
    vec2 rounded = abs(uv-0.5)-vec2(0.486,0.484);
    float sd = length(max(rounded,0.0))+min(max(rounded.x,rounded.y),0.0)-0.012;
    float alpha = 1.0-smoothstep(-0.001,0.001,sd);
    vec3 base = texture(TEXTURE,clamp(uv,vec2(0.0),vec2(1.0))).rgb;
    vec2 p = (uv-vec2(0.04,0.0857143))/vec2(0.92,0.7885714);
    float aspect = photo_size.x/max(photo_size.y,1.0);
    vec2 fit = vec2(min(1.0,aspect/(4.0/3.0)),min(1.0,(4.0/3.0)/aspect));
    vec2 inset = (vec2(1.0)-fit)*0.5;
    // The margin keeps every source corner visible at both tilt extremes.
    vec2 image_uv = ((p-0.5-tilt*photo_depth)/(1.0-photo_depth*2.0)+0.5-inset)/fit;
    float mask = step(0.0,image_uv.x)*step(image_uv.x,1.0)*step(0.0,image_uv.y)*step(image_uv.y,1.0);
    float window_mask = step(0.0,p.x)*step(p.x,1.0)*step(0.0,p.y)*step(p.y,1.0);
    base = mix(base,texture(photo,clamp(image_uv,vec2(0.0),vec2(1.0))).rgb,mask*window_mask);
    // View-driven foil, never time-driven. The photograph is excluded.
    if (effects_enabled) {
        float phase = uv.x*2.8+uv.y*1.7+tilt.x*1.9+tilt.y*1.3;
        vec3 spectrum = 0.55+0.45*cos(6.283185*(phase+vec3(0.0,0.33,0.67)));
        float edge = min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y));
        float rim = smoothstep(0.003,0.008,edge)*(1.0-smoothstep(0.026,0.038,edge));
        float sweep = pow(max(0.0,cos(phase*3.14159)),12.0);
        float foil = (rim*0.8+(1.0-window_mask)*sweep*0.14)*foil_strength;
        base = mix(base,spectrum*0.8+vec3(0.18),clamp(foil,0.0,0.9));
        vec2 grid = floor((uv+tilt*0.008)*vec2(160.0,140.0));
        float noise = fract(sin(dot(grid,vec2(12.9898,78.233)))*43758.5453);
        base += vec3(step(0.988,noise)*sweep*foil_strength*(1.0-window_mask)*0.3);
    }
    COLOR = vec4(base,alpha);
}
