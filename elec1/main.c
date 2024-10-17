//
//  main.c
//  elec1
//
//  Created by Toby Simpson on 05.02.24.
//

#include <stdio.h>
#include <math.h>

#ifdef __APPLE__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

//#include <Accelerate/Accelerate.h>

#include "ocl.h"
#include "msh.h"
#include "lvl.h"
#include "io.h"



//monodomain/ms/iso
int main(int argc, const char * argv[])
{
    printf("hello\n");
    
    printf("sizes %lu %lu %lu\n", sizeof(unsigned long), sizeof(size_t), sizeof(cl_ulong3));
    
    //ocl
    struct ocl_obj ocl;
    ocl_ini(&ocl);
    
    //level
    struct lvl_obj lvl;
    lvl.le = 6;
    lvl_ini(&lvl, &ocl);
    
    //dims
    size_t nv[3] = {lvl.msh.nv.x, lvl.msh.nv.y, lvl.msh.nv.z};

    /*
     ==============================
     init
     ==============================
     */
    
    //init
    ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, lvl.vtx_ini, 3, NULL, nv, NULL, 0, NULL, NULL);
    
    //time
    for(int t=0; t<100; t++)
    {
        printf("%02d\n",t);
        
        //write vtk
        wrt_vtk(&lvl, &ocl, t);

        //elec iter
        for(int k=0; k<100; k++)
        {
            //calc
            ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, lvl.vtx_ion, 3, NULL, nv, NULL, 0, NULL, NULL);

            //heart jacobi
            for(int l=0; l<10; l++)
            {
                ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, lvl.vtx_hrt, 3, NULL, nv, NULL, 0, NULL, NULL);
            }//l
            
            //torso jacobi
            for(int l=0; l<100; l++)
            {
                ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, lvl.vtx_trs, 3, NULL, nv, NULL, 0, NULL, NULL);
            }//l
            
        }//k
        
    }//t
    
    //clean
    ocl_fin(&ocl);
    
    printf("done.\n");
    
    return 0;
}
