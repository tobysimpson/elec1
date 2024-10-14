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




#endif /* geo_h */
