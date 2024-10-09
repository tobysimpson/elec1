//
//  io.h
//  mg1
//
//  Created by toby on 29.05.24.
//  Copyright © 2024 Toby Simpson. All rights reserved.
//

#ifndef io_h
#define io_h

#define ROOT_WRITE  "/Users/toby/Downloads/"


//write
void wrt_vtk(struct lvl_obj *lvl, struct ocl_obj *ocl, int frm_idx)
{
    FILE* file1;
    char file1_name[250];
    
    //file name
    sprintf(file1_name, "%s%s.%02d.%03d.vtk", ROOT_WRITE, "grid", lvl->le, frm_idx);
    
    //open
    file1 = fopen(file1_name,"wb");
    
    //write
    fprintf(file1,"# vtk DataFile Version 3.0\n");
    fprintf(file1,"grid1\n");
    fprintf(file1,"ASCII\n");
    fprintf(file1,"DATASET STRUCTURED_GRID\n");
    fprintf(file1,"DIMENSIONS %d %d %d\n", lvl->msh.nv.x, lvl->msh.nv.y, lvl->msh.nv.z);
    
    /*
     ===================
     coords
     ===================
     */
    
    fprintf(file1,"\nPOINTS %d float\n", lvl->msh.nv_tot);
    //map
    cl_float3 *xx = clEnqueueMapBuffer(ocl->command_queue, lvl->xx, CL_TRUE, CL_MAP_READ, 0, lvl->msh.nv_tot*sizeof(cl_float3), 0, NULL, NULL, &ocl->err);
    //write
    for(int i=0; i<lvl->msh.nv_tot; i++)
    {
        fprintf(file1, "%e %e %e\n", xx[i].x, xx[i].y, xx[i].z);
    }
    //unmap
    clEnqueueUnmapMemObject(ocl->command_queue, lvl->xx, xx, 0, NULL, NULL);
    
    
    //point data flag
    fprintf(file1,"\nPOINT_DATA %d\n", lvl->msh.nv_tot);
    
    
//    fprintf(file1,"VECTORS xx float\n");
//    //map
//    cl_float3 *vv = clEnqueueMapBuffer(ocl->command_queue, lvl->xx, CL_TRUE, CL_MAP_READ, 0, lvl->msh.nv_tot*sizeof(cl_float3), 0, NULL, NULL, &ocl->err);
//    //write
//    for(int i=0; i<lvl->msh.nv_tot; i++)
//    {
//        fprintf(file1, "%e %e %e\n", xx[i].x, xx[i].y, xx[i].z);
//    }
//    //unmap
//    clEnqueueUnmapMemObject(ocl->command_queue, lvl->xx, vv, 0, NULL, NULL);
    
    
    //uu
    fprintf(file1,"SCALARS uu float 1\n");
    fprintf(file1,"LOOKUP_TABLE default\n");
    //map
    float *uu = clEnqueueMapBuffer(ocl->command_queue, lvl->uu, CL_TRUE, CL_MAP_READ, 0, lvl->msh.nv_tot*sizeof(float), 0, NULL, NULL, &ocl->err);
    //write
    for(int i=0; i<lvl->msh.nv_tot; i++)
    {
        fprintf(file1, "%e\n", uu[i]);
    }
    //unmap
    clEnqueueUnmapMemObject(ocl->command_queue, lvl->uu, uu, 0, NULL, NULL);
    

    //clean up
    fclose(file1);
    
    return;
}


#endif /* io_h */
