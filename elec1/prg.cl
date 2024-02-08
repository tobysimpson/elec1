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

union float4x4
{
    float16 vec;
    float   arr[4][4];
};


/*
 ===================================
 prototypes
 ===================================
 */

int     fn_idx1(int3 pos, int3 dim);
int     fn_idx3(int3 pos);

int     fn_bnd1(int3 pos, int3 dim);
int     fn_bnd2(int3 pos, int3 dim);

void    mem_gr3(global float4 *buf, float4 uu3[27], int3 pos, int3 dim);
void    mem_lr2(float4 uu3[27], float4 uu2[8], int3 pos);

/*
 ===================================
 constants
 ===================================
 */

constant int3 off2[8] = {{0,0,0},{1,0,0},{0,1,0},{1,1,0},{0,0,1},{1,0,1},{0,1,1},{1,1,1}};

constant int3 off3[27] = {{0,0,0},{1,0,0},{2,0,0},{0,1,0},{1,1,0},{2,1,0},{0,2,0},{1,2,0},{2,2,0},
                          {0,0,1},{1,0,1},{2,0,1},{0,1,1},{1,1,1},{2,1,1},{0,2,1},{1,2,1},{2,2,1},
                          {0,0,2},{1,0,2},{2,0,2},{0,1,2},{1,1,2},{2,1,2},{0,2,2},{1,2,2},{2,2,2}};

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
 memory
 ===================================
 */

//global read 3x3x3 vectors
void mem_gr3(global float4 *buf, float4 uu3[27], int3 pos, int3 dim)
{
    for(int i=0; i<27; i++)
    {
        int3 adj_pos1 = pos + off3[i] - 1;
        int  adj_idx1 = fn_idx1(adj_pos1, dim);
        
        //copy/cast
        uu3[i] = buf[adj_idx1];
    }
    return;
}

//local read 2x2x2 from 3x3x3 vector
void mem_lr2(float4 uu3[27], float4 uu2[8], int3 pos)
{
    for(int i=0; i<8; i++)
    {
        int3 adj_pos3 = pos + off2[i];
        int  adj_idx3 = fn_idx3(adj_pos3);
        
        //copy
        uu2[i] = uu3[adj_idx3];
    }
    return;
}


/*
 ===================================
 kernels
 ===================================
 */

//init
kernel void vtx_init(const  float4  dx,
                     global float4  *vtx_xx,
                     global float4  *vtx_uu)
{
    int3 vtx_dim = {get_global_size(0), get_global_size(1), get_global_size(2)};
    int3 vtx1_pos1 = {get_global_id(0)  , get_global_id(1),   get_global_id(2)};
    int  vtx1_idx1 = fn_idx1(vtx1_pos1, vtx_dim);
    
    //vec
    vtx_xx[vtx1_idx1] = dx*convert_float4((int4){vtx1_pos1,0});
    vtx_uu[vtx1_idx1] = 0e0f;

    return;
}

//calc
kernel void vtx_calc(const  float4  dx,
                     global float4  *vtx_xx,
                     global float4  *vtx_uu)
{
    int3 vtx_dim = {get_global_size(0), get_global_size(1), get_global_size(2)};
    int3 vtx1_pos1 = {get_global_id(0)  , get_global_id(1),   get_global_id(2)};
    int  vtx1_idx1 = fn_idx1(vtx1_pos1, vtx_dim);
    
    //vec
    vtx_uu[vtx1_idx1] += 1e0f;

    return;
}
