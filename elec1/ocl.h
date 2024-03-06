//
//  ocl.h
//  elec1
//
//  Created by Toby Simpson on 08.02.24.
//

#ifndef ocl_h
#define ocl_h


#define ROOT_PRG    "/Users/toby/Documents/USI/postdoc/cardiac/xcode/elec1/elec1"

/*
 ===================================
 struct
 ===================================
 */

struct buf_float4
{
    cl_float4*      hst;
    cl_mem          dev;
};



struct state
{
    float Vm;       // (volt)          (in Membrane)
    float Ca_SR;    // (millimolar)    (in calcium_dynamics)
    float Cai;      // (millimolar)    (in calcium_dynamics)
    float g;        // NOT USED
    float d;        // (dimensionless) (in i_CaL_d_gate)
    float f1;       // (dimensionless) (in i_CaL_f1_gate)
    float f2;       // (dimensionless) (in i_CaL_f2_gate)
    float fCa;      // (dimensionless) (in i_CaL_fCa_gate)
    float Xr1;      // (dimensionless) (in i_Kr_Xr1_gate)
    float Xr2;      // (dimensionless) (in i_Kr_Xr2_gate)
    float Xs;       // (dimensionless) (in i_Ks_Xs_gate)
    float h;        // (dimensionless) (in i_Na_h_gate)
    float j;        // (dimensionless) (in i_Na_j_gate)
    float m;        // (dimensionless) (in i_Na_m_gate)
    float Xf;       // (dimensionless) (in i_f_Xf_gate)
    float q;        // (dimensionless) (in i_to_q_gate)
    float r;        // (dimensionless) (in i_to_r_gate)
    float Nai;      // (millimolar)    (in sodium_dynamics)
    float m_L;      // (dimensionless) (in i_NaL_m_gate)
    float h_L;      // (dimensionless) (in i_NaL_h_gate)
    float RyRa;     // (dimensionless) (in calcium_dynamics)
    float RyRo;     // (dimensionless) (in calcium_dynamics)
    float RyRc;     // (dimensionless) (in calcium_dynamics)
};

struct buf_state
{
    struct state*   hst;
    cl_mem          dev;
};


//object
struct ocl_obj
{
    //environment
    cl_int              err;
    cl_platform_id      platform_id;
    cl_device_id        device_id;
    cl_uint             num_devices;
    cl_uint             num_platforms;
    cl_context          context;
    cl_command_queue    command_queue;
    cl_program          program;
    char                device_str[100];
    cl_event            event;  //for profiling
        
    //memory
    struct buf_float4 vtx_xx;
    struct buf_float4 vtx_uu;
    struct buf_state  vtx_yy;

    //kernels
    cl_kernel vtx_init;
    cl_kernel vtx_memb;
};


/*
 ===================================
 init
 ===================================
 */

//init
void ocl_init(struct prm_obj *prm, struct ocl_obj *ocl)
{
    printf("__FILE__: %s\n", __FILE__);
    
    /*
     =============================
     environment
     =============================
     */
    
    ocl->err            = clGetPlatformIDs(1, &ocl->platform_id, &ocl->num_platforms);                                              //platform
    ocl->err            = clGetDeviceIDs(ocl->platform_id, CL_DEVICE_TYPE_GPU, 1, &ocl->device_id, &ocl->num_devices);              //devices
    ocl->context        = clCreateContext(NULL, ocl->num_devices, &ocl->device_id, NULL, NULL, &ocl->err);                          //context
    ocl->command_queue  = clCreateCommandQueue(ocl->context, ocl->device_id, CL_QUEUE_PROFILING_ENABLE, &ocl->err);                 //command queue
    ocl->err            = clGetDeviceInfo(ocl->device_id, CL_DEVICE_NAME, sizeof(ocl->device_str), &ocl->device_str, NULL);         //device info
    
    printf("%s\n", ocl->device_str);
    
    /*
     =============================
     program
     =============================
     */
    
    //name
    char prg_name[200];
    sprintf(prg_name,"%s/%s", ROOT_PRG, "prg.cl");

    printf("%s\n",prg_name);

    //file
    FILE* src_file = fopen(prg_name, "r");
    if(!src_file)
    {
        fprintf(stderr, "Failed to load kernel. check ROOT_PRG\n");
        exit(1);
    }

    //length
    fseek(src_file, 0, SEEK_END);
    size_t  prg_len =  ftell(src_file);
    rewind(src_file);

//    printf("%lu\n",prg_len);

    //source
    char *prg_src = (char*)malloc(prg_len);
    fread(prg_src, sizeof(char), prg_len, src_file);
    fclose(src_file);

//    printf("%s\n",prg_src);

    //create
    ocl->program = clCreateProgramWithSource(ocl->context, 1, (const char**)&prg_src, (const size_t*)&prg_len, &ocl->err);
    printf("prg %d\n",ocl->err);
    
    //clean
    free(prg_src);

    //build
    ocl->err = clBuildProgram(ocl->program, 1, &ocl->device_id, NULL, NULL, NULL);
    printf("bld %d\n",ocl->err);
    
    //unload compiler
    ocl->err = clUnloadPlatformCompiler(ocl->platform_id);
    
    /*
     =============================
     log
     =============================
     */

    //log
    size_t log_size = 0;
    
    //log size
    clGetProgramBuildInfo(ocl->program, ocl->device_id, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);

    //allocate
    char *log = (char*)malloc(log_size);

    //log text
    clGetProgramBuildInfo(ocl->program, ocl->device_id, CL_PROGRAM_BUILD_LOG, log_size, log, NULL);

    //print
    printf("%s\n", log);

    //clear
    free(log);
    
    /*
     =============================
     kernels
     =============================
     */

    ocl->vtx_init = clCreateKernel(ocl->program, "vtx_init", &ocl->err);
    ocl->vtx_memb = clCreateKernel(ocl->program, "vtx_memb", &ocl->err);

    /*
     =============================
     memory
     =============================
     */
    
    //CL_MEM_READ_WRITE/CL_MEM_HOST_READ_ONLY/CL_MEM_HOST_NO_ACCESS / CL_MEM_ALLOC_HOST_PTR
    
    //host
    ocl->vtx_xx.hst = malloc(prm->nv_tot*sizeof(cl_float4));
    ocl->vtx_uu.hst = malloc(prm->nv_tot*sizeof(cl_float4));
    ocl->vtx_yy.hst = malloc(prm->nv_tot*sizeof(struct state));
    
    //device
    ocl->vtx_xx.dev = clCreateBuffer(ocl->context, CL_MEM_HOST_READ_ONLY, prm->nv_tot*sizeof(cl_float4), NULL, &ocl->err);
    ocl->vtx_uu.dev = clCreateBuffer(ocl->context, CL_MEM_HOST_READ_ONLY, prm->nv_tot*sizeof(cl_float4), NULL, &ocl->err);
    ocl->vtx_yy.dev = clCreateBuffer(ocl->context, CL_MEM_HOST_READ_ONLY, prm->nv_tot*sizeof(struct state), NULL, &ocl->err);
    
    /*
     =============================
     arguments
     =============================
     */

    ocl->err = clSetKernelArg(ocl->vtx_init,  0, sizeof(cl_float4), (void*)&prm->x0);
    ocl->err = clSetKernelArg(ocl->vtx_init,  1, sizeof(cl_float4), (void*)&prm->dx);
    ocl->err = clSetKernelArg(ocl->vtx_init,  2, sizeof(cl_mem),    (void*)&ocl->vtx_xx.dev);
    ocl->err = clSetKernelArg(ocl->vtx_init,  3, sizeof(cl_mem),    (void*)&ocl->vtx_uu.dev);
    ocl->err = clSetKernelArg(ocl->vtx_init,  4, sizeof(cl_mem),    (void*)&ocl->vtx_yy.dev);

    ocl->err = clSetKernelArg(ocl->vtx_memb,  0, sizeof(cl_float4), (void*)&prm->dx);
    ocl->err = clSetKernelArg(ocl->vtx_memb,  1, sizeof(cl_mem),    (void*)&ocl->vtx_xx.dev);
    ocl->err = clSetKernelArg(ocl->vtx_memb,  2, sizeof(cl_mem),    (void*)&ocl->vtx_uu.dev);
    ocl->err = clSetKernelArg(ocl->vtx_memb,  3, sizeof(cl_mem),    (void*)&ocl->vtx_yy.dev);
}


//final
void ocl_final(struct prm_obj *msh, struct ocl_obj *ocl)
{
    ocl->err = clFlush(ocl->command_queue);
    ocl->err = clFinish(ocl->command_queue);
    
    //kernels
    ocl->err = clReleaseKernel(ocl->vtx_init);
    ocl->err = clReleaseKernel(ocl->vtx_memb);
    
    //memory
    ocl->err = clReleaseMemObject(ocl->vtx_xx.dev);
    ocl->err = clReleaseMemObject(ocl->vtx_uu.dev);
    ocl->err = clReleaseMemObject(ocl->vtx_yy.dev);
    
    free(ocl->vtx_xx.hst);
    free(ocl->vtx_uu.hst);
    free(ocl->vtx_yy.hst);
    
    //context
    ocl->err = clReleaseProgram(ocl->program);
    ocl->err = clReleaseCommandQueue(ocl->command_queue);
    ocl->err = clReleaseContext(ocl->context);
    
    return;
}


#endif /* ocl_h */

