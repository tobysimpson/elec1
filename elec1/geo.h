//
//  geo.h
//  elec1
//
//  Created by Toby Simpson on 14.10.2024.
//

#ifndef geo_h
#define geo_h


//cuboid
float sdf_cub(float3 x, float3 c, float3 r)
{
    float3 d = fabs(x - c) - r;
    
    return max(d.x,max(d.y,d.z));
}

//cuboid
float sdf_sph(float3 x, float3 c, float r)
{
    return length(x - c) - r;
}


//stimulus
float fn_g0(float3 x)
{
    float3 c = (float3){-7e0f, -7e0f, -7e0f};
    float3 r = (float3){ 1e0f,  1e0f,  1e0f};
    
    return sdf_cub(x, c, r);
}


//heart
float fn_g1(float3 x)
{
    float3 c = (float3){0e0f, 0e0f, 0e0f};
    float3 r = (float3){8e0f, 8e0f, 8e0f};
    
    return sdf_cub(x, c, r);
}


#endif /* geo_h */
