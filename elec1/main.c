//
//  main.c
//  elec1
//
//  Created by Toby Simpson on 05.02.24.
//

#include <stdio.h>
#include <OpenCL/opencl.h>
//#include <Accelerate/Accelerate.h>

#include "prm.h"
#include "ocl.h"
#include "io.h"



//Paci2018
int main(int argc, const char * argv[])
{
    printf("hello\n");
    
    //objects
    struct prm_obj prm;
    struct ocl_obj ocl;
    
    //init obj
    prm_init(&prm);
    ocl_init(&prm, &ocl);
    
    //cast dims
    size_t nv[3] = {prm.vtx_dim.x, prm.vtx_dim.y, prm.vtx_dim.z};
    size_t iv[3] = {prm.vtx_dim.x-2, prm.vtx_dim.y-2, prm.vtx_dim.z-2};
    
    /*
     ==============================
     init
     ==============================
     */
    
    //init
    ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, ocl.vtx_init, 3, NULL, nv, NULL, 0, NULL, NULL);
    
    //time
    for(int t=0; t<100; t++)
    {
        printf("%2d\n",t);
        
        //read vec
        ocl.err = clEnqueueReadBuffer(ocl.command_queue, ocl.vtx_xx.dev, CL_TRUE, 0, prm.nv_tot*sizeof(cl_float4),    ocl.vtx_xx.hst,  0, NULL, NULL);
        ocl.err = clEnqueueReadBuffer(ocl.command_queue, ocl.vtx_uu.dev, CL_TRUE, 0, prm.nv_tot*sizeof(cl_float4),    ocl.vtx_uu.hst,  0, NULL, NULL);
//        ocl.err = clEnqueueReadBuffer(ocl.command_queue, ocl.vtx_yy.dev, CL_TRUE, 0, prm.nv_tot*sizeof(struct state), ocl.vtx_yy.hst,  0, NULL, NULL);
        
        //write vtk
        wrt_vtk(&prm, &ocl, t);
        
        for(int k=0; k<5000; k++)
        {
            //calc
//            ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, ocl.vtx_memb, 3, NULL, nv, NULL, 0, NULL, NULL);
        ocl.err = clEnqueueNDRangeKernel(ocl.command_queue, ocl.vtx_diff, 3, NULL, iv, NULL, 0, NULL, NULL);

        }
        
        
    }
    
    //clean
    ocl_final(&prm, &ocl);
    
    printf("done.\n");
    
    return 0;
}
