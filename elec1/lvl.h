//
//  lvl.h
//  elec1
//
//  Created by Toby Simpson on 09.10.2024.
//

#ifndef lvl_h
#define lvl_h


//object
struct lvl_obj
{
    int             le;     //log2(ne)
    struct  msh_obj msh;
    
    //memory
    cl_mem          xx;
    cl_mem          uu;
    
    //kernels
    cl_kernel       vtx_ini;
};


void lvl_ini(struct lvl_obj *lvl, struct ocl_obj *ocl)
{
    printf("le %d\n", lvl->le);
    
    //mesh
    int ne = pow(2,lvl->le);
    int nv = ne+1;
    
    lvl->msh.dx     = 1e+0f;
    lvl->msh.dt     = 1e-1f;
    
    lvl->msh.ne     = (cl_int3){ne,ne,ne};
    lvl->msh.nv     = (cl_int3){nv,nv,nv};
    
    lvl->msh.ne_tot = ne*ne*ne;
    lvl->msh.nv_tot = nv*nv*nv;
    
    msh_ini(&lvl->msh);
    
    //memory
    lvl->xx = clCreateBuffer(ocl->context, CL_MEM_HOST_READ_ONLY, lvl->msh.nv_tot*sizeof(cl_float4), NULL, &ocl->err);
    lvl->uu = clCreateBuffer(ocl->context, CL_MEM_HOST_READ_ONLY, lvl->msh.nv_tot*sizeof(cl_float4), NULL, &ocl->err);
    
    //kernels
    lvl->vtx_ini = clCreateKernel(ocl->program, "vtx_ini", &ocl->err);
    
    //arguments
    ocl->err = clSetKernelArg(lvl->vtx_ini,  0, sizeof(struct msh_obj),    (void*)&lvl->msh);
    ocl->err = clSetKernelArg(lvl->vtx_ini,  1, sizeof(cl_mem),            (void*)&lvl->xx);
    ocl->err = clSetKernelArg(lvl->vtx_ini,  2, sizeof(cl_mem),            (void*)&lvl->uu);
    
    return;
}


void lvl_fin(struct lvl_obj *lvl, struct ocl_obj *ocl)
{
    //kernels
    ocl->err = clReleaseKernel(lvl->vtx_ini);
    
    //memory
    ocl->err = clReleaseMemObject(lvl->xx);
    ocl->err = clReleaseMemObject(lvl->uu);
    
    return;
}



#endif /* lvl_h */
