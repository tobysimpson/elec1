//
//  msh.h
//  elec1
//
//  Created by Toby Simpson on 09.10.2024.
//

#ifndef msh_h
#define msh_h

//object
struct msh_obj
{
    float   dx;
    float   dt;
    
    cl_int3 ne;
    cl_int3 nv;
    
    int     ne_tot;
    int     nv_tot;
};


void msh_ini(struct msh_obj *msh)
{
    printf("%e %e\n",msh->dx, msh->dt);
    
    return;
}

#endif /* msh_h */
