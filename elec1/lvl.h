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
};


void lvl_ini(struct lvl_obj *lvl, struct ocl_obj *ocl)
{
    int ne = pow(2,lvl->le);
    int nv = ne+1;
    
    lvl->msh.dx     = 1e+0f;
    lvl->msh.dt     = 1e+0f;
    
    lvl->msh.ne     = (cl_int3){ne,ne,ne};
    lvl->msh.nv     = (cl_int3){nv,nv,nv};
    
    lvl->msh.ne_tot = ne*ne*ne;
    lvl->msh.nv_tot = nv*nv*nv;
    
    msh_ini(&lvl->msh);

    return;
}

void lvl_fin(struct lvl_obj *lvl, struct ocl_obj *ocl)
{
    ocl->err = clReleaseMemObject(lvl->xx);
    ocl->err = clReleaseMemObject(lvl->uu);
    
    return;
}



#endif /* lvl_h */
