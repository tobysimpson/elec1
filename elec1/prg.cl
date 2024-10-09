//
//  prg.cl
//  elec1
//
//  Created by Toby Simpson on 08.02.24.
//

/*
 ===================================
 struct
 ===================================
 */

//object
struct msh_obj
{
    float   dx;
    float   dt;
    
    int3    ne;
    int3    nv;
    
    int     ne_tot;
    int     nv_tot;
};


/*
 ===================================
 prototypes
 ===================================
 */

int     fn_idx1(int3 pos, int3 dim);
int     fn_idx3(int3 pos);


/*
 ===================================
 constants
 ===================================
 */

constant int3 off2[8] = {{0,0,0},{1,0,0},{0,1,0},{1,1,0},{0,0,1},{1,0,1},{0,1,1},{1,1,1}};

constant int3 off3[27] = {{0,0,0},{1,0,0},{2,0,0},{0,1,0},{1,1,0},{2,1,0},{0,2,0},{1,2,0},{2,2,0},
                          {0,0,1},{1,0,1},{2,0,1},{0,1,1},{1,1,1},{2,1,1},{0,2,1},{1,2,1},{2,2,1},
                          {0,0,2},{1,0,2},{2,0,2},{0,1,2},{1,1,2},{2,1,2},{0,2,2},{1,2,2},{2,2,2}};

//mitchell-schaffer
constant float MS_V_GATE    = 0.13f;        //dimensionless (13 in the paper 15 for N?)
constant float MS_TAU_IN    = 0.3f;         //milliseconds
constant float MS_TAU_OUT   = 6.0f;         //should be 6.0
constant float MS_TAU_OPEN  = 120.0f;       //milliseconds
constant float MS_TAU_CLOSE = 130.0f;       //90 endocardium or 130 epi - longer

/*
 ===================================
 utilities
 ===================================
 */

//flat index
int fn_idx1(int3 pos, int3 dim)
{
    return pos.x + dim.x*(pos.y + dim.y*pos.z);
}

//index 3x3x3
int fn_idx3(int3 pos)
{
    return pos.x + 3*pos.y + 9*pos.z;
}

//in-bounds
int fn_bnd1(int3 pos, int3 dim)
{
    return all(pos>=0)*all(pos<dim);
}

//on the boundary
int fn_bnd2(int3 pos, int3 dim)
{
    return (pos.x==0)||(pos.y==0)||(pos.z==0)||(pos.x==dim.x-1)||(pos.y==dim.y-1)||(pos.z==dim.z-1);
}

/*
 ===================================
 kernels
 ===================================
 */

//init
kernel void vtx_ini(const  struct msh_obj  msh,
                    global float4          *xx,
                    global float4          *uu)
{
    int3 vtx_pos  = {get_global_id(0), get_global_id(1), get_global_id(2)};
    int  vtx_idx  = fn_idx1(vtx_pos, msh.nv);

    float4 x = (float4){msh.dx*convert_float3(vtx_pos), 0e0f};

    xx[vtx_idx] = x;
    uu[vtx_idx] = (float4){all(vtx_pos.xyz<4),1.0f,0e0f,0e0f};

    return;
}


//mitchell-schaffer
kernel void vtx_ion(const  struct msh_obj  msh,
                    global float4          *uu)
{
    int3 vtx_pos  = {get_global_id(0), get_global_id(1), get_global_id(2)};
    int  vtx_idx  = fn_idx1(vtx_pos, msh.nv);

    float2 u = uu[vtx_idx].xy;
    float2 du = 0.0f;

    //mitchell-schaffer
    du.x = (u.y*u.x*u.x*(1.0f-u.x)/MS_TAU_IN) - (u.x/MS_TAU_OUT);               //ms dimensionless J_in, J_out, J_stim
    du.y = (u.x<MS_V_GATE)?((1.0f - u.y)/MS_TAU_OPEN):(-u.y)/MS_TAU_CLOSE;      //gating variable

    //update
    u.xy += msh.dt*du;

    //store
    uu[vtx_idx].xy = u.xy;

    return;
}



