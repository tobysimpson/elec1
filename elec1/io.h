//
//  io.h
//  elec1
//
//  Created by Toby Simpson on 08.02.24.
//

#ifndef io_h
#define io_h


#define ROOT_WRITE  "/Users/toby/Downloads/"

//write
void wrt_raw(void *ptr, size_t n, size_t bytes, char *file_name)
{
//    printf("%s\n",file_name);
    
    //name
    char file_path[250];
    sprintf(file_path, "%s%s.raw", ROOT_WRITE, file_name);

    //open
    FILE* file = fopen(file_path,"wb");
  
    //write
    fwrite(ptr, bytes, n, file);
    
    //close
    fclose(file);
    
    return;
}


//write
void wrt_vtk(struct prm_obj *prm, struct ocl_obj *ocl, int k)
{

    FILE* file1;
    char file1_name[250];
    
    //file name
    sprintf(file1_name, "%s%s.%03d.vtk", ROOT_WRITE, "grid1", k);
    
    //open
    file1 = fopen(file1_name,"w");
    
    //write
    fprintf(file1,"# vtk DataFile Version 3.0\n");
    fprintf(file1,"grid1\n");
    fprintf(file1,"ASCII\n");
    fprintf(file1,"DATASET STRUCTURED_GRID\n");
    fprintf(file1,"DIMENSIONS %d %d %d\n", prm->vtx_dim.x, prm->vtx_dim.y, prm->vtx_dim.z);
    
    /*
     ===================
     coords
     ===================
     */
    
    fprintf(file1,"\nPOINTS %d float\n", prm->nv_tot);

    for(int i=0; i<prm->nv_tot; i++)
    {
        fprintf(file1, "%e %e %e\n", ocl->vtx_xx.hst[i].x, ocl->vtx_xx.hst[i].y, ocl->vtx_xx.hst[i].z);
    }

    //point data flag
    fprintf(file1,"\nPOINT_DATA %d\n", prm->nv_tot);
    

    /*
     ===================
     scalars
     ===================
     */
    
    fprintf(file1,"SCALARS uu float 4\n");
    fprintf(file1,"LOOKUP_TABLE default\n");
    
    for(int i=0; i<prm->nv_tot; i++)
    {
        fprintf(file1, "%e %e %e %e\n", ocl->vtx_uu.hst[i].x, ocl->vtx_uu.hst[i].y, ocl->vtx_uu.hst[i].z, ocl->vtx_uu.hst[i].w);
    }
    
    
    //clean up
    fclose(file1);

    return;
}

#endif /* io_h */
