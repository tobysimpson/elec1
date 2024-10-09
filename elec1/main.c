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

//

//Paci2018
int main(int argc, const char * argv[])
{
    printf("hello\n");
    
    //ocl
    struct ocl_obj ocl;
    ocl_ini(&ocl);
    
    //level
    struct lvl_obj lvl;
    lvl.le = 2;
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
    
    //write
    wrt_vtk(&lvl, &ocl, 0);
    
//    //time
//    for(int t=0; t<100; t++)
//    {
//        printf("%2d\n",t);
//        
//
//        
    //        //write vtk
    //        wrt_vtk(&lvl, &ocl, t);
//
//        for(int k=0; k<5000; k++)
//        {
//            //calc
////            ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, ocl.vtx_memb, 3, NULL, nv, NULL, 0, NULL, NULL);
////            ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, ocl.vtx_diff, 3, NULL, iv, NULL, 0, NULL, NULL);
//        }
//
//    }
    
    //clean
    ocl_fin(&ocl);
    
    printf("done.\n");
    
    return 0;
}
