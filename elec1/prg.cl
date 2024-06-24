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
kernel void vtx_init(const  float4          x0,
                     const  float4          dx,
                     global float4          *vtx_xx,
                     global float4          *vtx_uu,
                     global struct state    *vtx_yy)
{
    int3 vtx_dim = {get_global_size(0), get_global_size(1), get_global_size(2)};
    int3 vtx1_pos1 = {get_global_id(0)  , get_global_id(1),   get_global_id(2)};
    int  vtx1_idx1 = fn_idx1(vtx1_pos1, vtx_dim);
    
    float4 x = x0 + dx*convert_float4((int4){vtx1_pos1,0});

    //init
    struct state y;
    y.Vm    = -0.0749228904740065f;
    y.Ca_SR = +0.0936532528714175f;
    y.Cai   = +3.79675694306440e-05f;
    y.g     = +0.0f;
    y.d     = +8.25220533963093e-05f;
    y.f1    = +0.741143500777858f;
    y.f2    = +0.999983958619179f;
    y.fCa   = +0.997742015033076f;
    y.Xr1   = +0.266113517200784f;
    y.Xr2   = +0.434907203275640f;
    y.Xs    = +0.0314334976383401f;
    y.h     = +0.745356534740988f;
    y.j     = +0.0760523580322096f;
    y.m     = +0.0995891726023512f;
    y.Xf    = +0.0249102482276486f;
    y.q     = +0.841714924246004f;
    y.r     = +0.00558005376429710f;
    y.Nai   = +8.64821066193476f;
    y.m_L   = +0.00225383437957339f;
    y.h_L   = +0.0811507312565017f;
    y.RyRa  = +0.0387066722172937f;
    y.RyRo  = +0.0260449185736275f;
    y.RyRc  = +0.0785849084330126f;
    
    //write
    vtx_xx[vtx1_idx1] = x;
    vtx_uu[vtx1_idx1] = 0e0f;
    vtx_yy[vtx1_idx1] = y;
    
    return;
}


//calc
kernel void vtx_memb(const  float4          dx,
                     global float4          *vtx_xx,
                     global float4          *vtx_uu,
                     global struct state    *vtx_yy)
{
    int3 vtx_dim = {get_global_size(0), get_global_size(1), get_global_size(2)};
    int3 vtx1_pos1 = {get_global_id(0)  , get_global_id(1),   get_global_id(2)};
    int  vtx1_idx1 = fn_idx1(vtx1_pos1, vtx_dim);
    
    //vec
    vtx_uu[vtx1_idx1].x += 1e0f;
    vtx_uu[vtx1_idx1].y += dx.w;
    
    //vars
    struct state y = vtx_yy[vtx1_idx1];
    struct state dy;
    
    //from matlab
    const float VmaxUp      = 0.5113f;       // millimolar_per_second (in calcium_dynamics)
    const float g_irel_max  = 62.5434f;      // millimolar_per_second (in calcium_dynamics)
    const float RyRa1       = 0.05354f;      // uM
    const float RyRa2       = 0.0488f;       // uM
    const float RyRahalf    = 0.02427f;      // uM
    const float RyRohalf    = 0.01042f;      // uM
    const float RyRchalf    = 0.00144f;      // uM
    const float kNaCa       = 3917.0463f;    // A_per_F (in i_NaCa)
    const float PNaK        = 2.6351f;       // A_per_F (in i_NaK)
    const float Kup         = 3.1928e-4f;    // millimolar (in calcium_dynamics)
    const float V_leak      = 4.7279e-4f;    // per_second (in calcium_dynamics)
    const float alpha       = 2.5371f;       // dimensionless (in i_NaCa)

    //Constants
    const float F           = 96485.3415f;   // coulomb_per_mole (in model_parameters)
    const float R           = 8.314472f;     // joule_per_mole_kelvin (in model_parameters)
    const float T           = 310.0f;        // kelvin (in model_parameters)

    //Cell geometry
    const float V_SR        = 583.73f;       // micrometre_cube (in model_parameters)
    const float Vc          = 8.80000e+03f;       // micrometre_cube (in model_parameters)
//    const float Cm          = 9.87109e-11f;  // farad (in model_parameters)
    const float Cm          = 98710900e0f;  // scaled for cell volume in m^3 = Cm/1e-18f
    
    //he gives cell volume in m^3?? then divides by 1e-18
    //we avoid with intermediate Cm_scaled Cm/(F*Vc*1e-18)

    // Extracellular concentrations
    const float Nao         = 151.0f;        // millimolar (in model_parameters)
    const float Ko          = 5.4f;          // millimolar (in model_parameters)
    const float Cao         = 1.8f;          //3;//5;//1.8;   // millimolar (in model_parameters)

    // Intracellular concentrations
    // Naio = 10 mM y.Nai
    const float Ki          = 150.0f;        // millimolar (in model_parameters)
    // Cai  = 0.0002 mM y.Cai
    // caSR = 0.3 mM y.Ca_SR

    //Nernst potential
    const float E_Na        = R*T/F*log(Nao/y.Nai);
    const float E_Ca        = 0.5f*R*T/F*log(Cao/y.Cai);
    const float E_K         = R*T/F*log(Ko/Ki);
    const float PkNa        = 0.03f;                                        // dimensionless (in electric_potentials)
    const float E_Ks        = R*T/F*log((Ko+PkNa*Nao)/(Ki+PkNa*y.Nai));

    // INa
    const float g_Na        = 3671.2302f;   // S_per_F (in i_Na)
//    const float i_Na        = ((time<tDrugApplication)*1+(time >= tDrugApplication)*INaFRedMed)*g_Na*y.m^3.0*Y(12)*y.j*(y.Vm-E_Na);
    const float i_Na        = g_Na*pown(y.m,3)*y.h*y.j*(y.Vm-E_Na);          //no drug


    const float h_inf       = 1.0f/sqrt(1.0f+exp((y.Vm*1e+3f+72.1f)/5.7f));
    const float alpha_h     = 0.057f*exp(-(y.Vm*1e+3f+80.0f)/6.8f);
    const float beta_h      = 2.7f*exp(0.079f*y.Vm*1e+3f)+3.1f*pown(10.0f,5)*exp(0.3485f*y.Vm*1e+3f);
    const float tau_h       = (y.Vm < -0.0385f) ? 1.5f/((alpha_h+beta_h)*1e+3f) : 1.5f*1.6947f/1e+3f;

    dy.h                    = (h_inf-y.h)/tau_h;

    const float j_inf       = 1.0f/sqrt(1.0f+exp((y.Vm*1e+3f+72.1f)/5.7f));
    const float alpha_j     = (y.Vm < -0.04f) ? (-25428.0f*exp(0.2444f*y.Vm*1e+3f)-6.948f*1e-6f*exp(-0.04391f*y.Vm*1e+3f))*(y.Vm*1e+3f+37.78f)/(1.0f+exp(0.311f*(y.Vm*1e+3f+79.23f))) : 0.0f;
    const float beta_j      = (y.Vm < -0.04f) ? ((0.02424f*exp(-0.01052f*y.Vm*1e+3f)/(1e0f+exp(-0.1378f*(y.Vm*1e+3f+40.14f))))) : ((0.6f*exp((0.057f)*y.Vm*1e+3f)/(1e0f+exp(-0.1f*(y.Vm*1e+3f+32e0f)))));
    const float tau_j       = 7.0f/((alpha_j+beta_j)*1e+3f);
    
    dy.j                    = (j_inf-y.j)/tau_j;

    const float m_inf       = 1.0f/pow((1.0f+exp((-y.Vm*1e+3f-34.1f)/5.9f)),(1.0f/3.0f));
    const float alpha_m     = 1.0f/(1.0f+exp((-y.Vm*1e+3f-60.0f)/5.0f));
    const float beta_m      = 0.1f/(1.0f+exp((y.Vm*1e+3f+35.0f)/5.0f))+0.1f/(1.0f+exp((y.Vm*1e+3f-50.0f)/200.0f));
    const float tau_m       = 1.0f*alpha_m*beta_m/1e+3f;
    
    dy.m                    = (m_inf-y.m)/tau_m;

    //INaL
    const float myCoefTauM  = 1e0f;
    const float tauINaL     = 200e0f; //ms
    const float GNaLmax     = 2.3f*7.5f; //(S/F)
    const float Vh_hLate    = 87.61f;
    const float i_NaL       = GNaLmax*pown(y.m_L,3)*y.h_L*(y.Vm-E_Na);

    const float m_inf_L     = 1e0f/(1e0f+exp(-(y.Vm*1e+3f+42.85f)/(5.264f)));
    const float alpha_m_L   = 1e0f/(1e0f+exp((-60e0f-y.Vm*1e+3f)/5e0f));
    const float beta_m_L    = 0.1f/(1e0f+exp((y.Vm*1e+3f+35e0f)/5e0f))+0.1f/(1e0f+exp((y.Vm*1e+3f-50e0f)/200e0f));
    const float tau_m_L     = 1e-3f * myCoefTauM*alpha_m_L*beta_m_L;
    
    dy.m_L                  = (m_inf_L-y.m_L)/tau_m_L;

    const float h_inf_L     = 1e0f/(1e0f+exp((y.Vm*1e+3f+Vh_hLate)/(7.488f)));
    const float tau_h_L     = 1e-3f * tauINaL;
    
    dy.h_L                  = (h_inf_L-y.h_L)/tau_h_L;

    //If
    const float E_f         = -0.017f;       // volt (in i_f)
    const float g_f         = 30.10312f;     // S_per_F (in i_f)

    const float i_f         = g_f*y.Xf*(y.Vm-E_f);
    const float i_fNa       = 0.42f*g_f*y.Xf*(y.Vm-E_Na);

    const float Xf_infinity = 1.0f/(1.0f+exp((y.Vm*1e+3f+77.85f)/5.0f));
    const float tau_Xf      = 1900.0f/(1.0f+exp((y.Vm*1e+3f+15.0f)/10.0f))/1e+3f;
    
    dy.Xf                   = (Xf_infinity-y.Xf)/tau_Xf;

    //ICaL
    const float g_CaL       = 8.635702e-5f;   // metre_cube_per_F_per_s (in i_CaL)
//    const float i_CaL       = ((time<tDrugApplication)*1+(time >= tDrugApplication)*ICaLRedMed)*g_CaL*4.0*y.Vm*F^2.0/(R*T)*(y.Cai*exp(2.0*y.Vm*F/(R*T))-0.341*Cao)/(exp(2.0*y.Vm*F/(R*T))-1.0)*y.d*y.f1*y.f2*y.fCa;
    const float i_CaL       = g_CaL*4.0f*y.Vm*pown(F,2)/(R*T)*(y.Cai*exp(2.0f*y.Vm*F/(R*T))-0.341f*Cao)/(exp(2.0f*y.Vm*F/(R*T))-1.0f)*y.d*y.f1*y.f2*y.fCa; //no drug

    const float d_infinity  = 1.0f/(1.0f+exp(-(y.Vm*1e+3f+9.1f)/7.0f));
    const float alpha_d     = 0.25f+1.4f/(1.0f+exp((-y.Vm*1e+3f-35.0f)/13.0f));
    const float beta_d      = 1.4f/(1.0f+exp((y.Vm*1e+3f+5.0f)/5.0f));
    const float gamma_d     = 1.0f/(1.0f+exp((-y.Vm*1e+3f+50.0f)/20.0f));
    const float tau_d       = (alpha_d*beta_d+gamma_d)*1.0f/1e+3f;
    
    dy.d                    = (d_infinity-y.d)/tau_d;

    const float f1_inf      = 1.0f/(1.0f+exp((y.Vm*1e+3f+26.0f)/3.0f));
    const float constf1     = (f1_inf-y.f1 > 0.0f) ? 1.0f+1433.0f*(y.Cai-50.0f*1.0e-6f) : 1.0f;
    const float tau_f1      = (20.0f+1102.5f*exp(-pown(pown(y.Vm*1e+3f+27.0f,2)/15.0f,2))+200.0f/(1.0f+exp((13.0f-y.Vm*1e+3f)/10.0f))+180.0f/(1.0f+exp((30.0f+y.Vm*1e+3f)/10.0f)))*constf1*1e-3f;
    
    dy.f1                   = (f1_inf-y.f1)/tau_f1;

    const float f2_inf      = 0.33f+0.67f/(1.0f+exp((y.Vm*1e+3f+32.0f)/4.0f));
    const float constf2     = 1.0f;
    const float tau_f2      = (600.0f*exp(-pown(y.Vm*1e+3f+25.0f,2)/170.0f)+31.0f/(1.0f+exp((25.0f-y.Vm*1e+3f)/10.0f))+16.0f/(1.0f+exp((30.0f+y.Vm*1e+3f)/10.0f)))*constf2/1e+3f;
    
    dy.f2                   = (f2_inf-y.f2)/tau_f2;

    const float alpha_fCa   = 1.0f/(1.0f+pown(y.Cai/0.0006f,8));
    const float beta_fCa    = 0.1f/(1.0f+exp((y.Cai-0.0009f)/0.0001f));
    const float gamma_fCa   = 0.3f/(1.0f+exp((y.Cai-0.00075f)/0.0008f));
    const float fCa_inf     = (alpha_fCa+beta_fCa+gamma_fCa)/1.3156f;
    const float constfCa    = ((y.Vm > -0.06f) && (fCa_inf > y.fCa)) ? 0e0f : 1e0f;
    const float tau_fCa     = 0.002f;   // second (in i_CaL_fCa_gate)
    
    dy.fCa                  = constfCa*(fCa_inf-y.fCa)/tau_fCa;

    //Ito
    const float g_to        = 29.9038f;   // S_per_F (in i_to)
    const float i_to        = g_to*(y.Vm-E_K)*y.q*y.r;
    const float q_inf       = 1.0f/(1.0f+exp((y.Vm*1e+3f+53.0f)/13.0f));
    const float tau_q       = (6.06f+39.102f/(0.57f*exp(-0.08f*(y.Vm*1e+3f+44.0f))+0.065f*exp(0.1f*(y.Vm*1e+3f+45.93f))))/1e+3f;
    
    dy.q                    = (q_inf-y.q)/tau_q;

    const float r_inf       = 1.0f/(1.0f+exp(-(y.Vm*1e+3f-22.3f)/18.75f));
    const float tau_r       = (2.75352f+14.40516f/(1.037f*exp(0.09f*(y.Vm*1e+3f+30.61f))+0.369f*exp(-0.12f*(y.Vm*1e+3f+23.84f))))/1e+3f;
    
    dy.r                    = (r_inf-y.r)/tau_r;

    // IKs
    const float g_Ks        = 2.041f;   // S_per_F (in i_Ks)
//    const float i_Ks        = ((time<tDrugApplication)*1+(time >= tDrugApplication)*IKsRedMed)*g_Ks*(y.Vm-E_Ks)*y.Xs^2.0*(1.0+0.6/(1.0+(3.8*0.00001/y.Cai)^1.4));
    const float i_Ks        = g_Ks*(y.Vm-E_Ks)*pown(y.Xs,2)*(1.0f+0.6f/(1.0f+pow(3.8f*0.00001f/y.Cai,1.4f)));     //no drug
    
    const float Xs_infinity = 1.0f/(1.0f+exp((-y.Vm*1e+3f-20.0f)/16.0f));
    const float alpha_Xs    = 1100.0f/sqrt(1.0f+exp((-10.0f-y.Vm*1e+3f)/6.0f));
    const float beta_Xs     = 1.0f/(1.0f+exp((-60.0f+y.Vm*1e+3f)/20.0f));
    const float tau_Xs      = 1.0f*alpha_Xs*beta_Xs/1e+3f;
    
    dy.Xs                   = (Xs_infinity-y.Xs)/tau_Xs;

    // IKr
    const float L0          = 0.025f;   // dimensionless (in i_Kr_Xr1_gate)
    const float Q           = 2.3f;   // dimensionless (in i_Kr_Xr1_gate)
    const float g_Kr        = 29.8667f;   // S_per_F (in i_Kr)
//    const float i_Kr         = ((time<tDrugApplication)*1+(time >= tDrugApplication)*IKrRedMed)*g_Kr*(y.Vm-E_K)*y.Xr1*y.Xr2*sqrt(Ko/5.4);
    const float i_Kr        = g_Kr*(y.Vm-E_K)*y.Xr1*y.Xr2*sqrt(Ko/5.4f);

    const float V_half      = 1e+3f*(-R*T/(F*Q)*log(pown(1.0f+Cao/2.6f,4)/(L0*pown(1.0f+Cao/0.58f,4)))-0.019f);

    const float Xr1_inf     = 1.0f/(1.0f+exp((V_half-y.Vm*1e+3f)/4.9f));
    const float alpha_Xr1   = 450.0f/(1.0f+exp((-45.0f-y.Vm*1e+3f)/10.0f));
    const float beta_Xr1    = 6.0f/(1.0f+exp((30.0f+y.Vm*1e+3f)/11.5f));
    const float tau_Xr1     = alpha_Xr1*beta_Xr1*1e-3f;
    
    dy.Xr1                  = (Xr1_inf-y.Xr1)/tau_Xr1;

    const float Xr2_infinity = 1.0f/(1.0f+exp((y.Vm*1e+3f+88.0f)/50.0f));
    const float alpha_Xr2    = 3.0f/(1.0f+exp((-60.0f-y.Vm*1e+3f)/20.0f));
    const float beta_Xr2     = 1.12f/(1.0f+exp((-60.0f+y.Vm*1e+3f)/20.0f));
    const float tau_Xr2      = 1.0f*alpha_Xr2*beta_Xr2/1e+3f;
    
    dy.Xr2                  = (Xr2_infinity-y.Xr2)/tau_Xr2;

    //IK1
    const float alpha_K1    = 3.91f/(1.0f+exp(0.5942f*(y.Vm*1e+3f-E_K*1e+3f-200.0f)));
    const float beta_K1     = (-1.509f*exp(0.0002f*(y.Vm*1e+3f-E_K*1e+3f+100.0f))+exp(0.5886f*(y.Vm*1e+3f-E_K*1e+3f-10.0f)))/(1.0f+exp(0.4547f*(y.Vm*1e+3f-E_K*1e+3f)));
    const float XK1_inf     = alpha_K1/(alpha_K1+beta_K1);
    const float g_K1        = 28.1492f;   // S_per_F (in i_K1)
    const float i_K1        = g_K1*XK1_inf*(y.Vm-E_K)*sqrt(Ko/5.4f);
    
    //INaCa
    const float KmCa        = 1.38f;   // millimolar (in i_NaCa)
    const float KmNai       = 87.5f;   // millimolar (in i_NaCa)
    const float Ksat        = 0.1f;   // dimensionless (in i_NaCa)
    const float gamma       = 0.35f;   // dimensionless (in i_NaCa)
    const float kNaCa1      = kNaCa;   // A_per_F (in i_NaCa)
    const float i_NaCa      = kNaCa1*(exp(gamma*y.Vm*F/(R*T))*pown(y.Nai,3)*Cao-exp((gamma-1.0f)*y.Vm*F/(R*T))*pown(Nao,3)*y.Cai*alpha)/((pown(KmNai,3)+pown(Nao,3))*(KmCa+Cao)*(1.0f+Ksat*exp((gamma-1.0f)*y.Vm*F/(R*T))));

    //INaK
    const float Km_K        = 1.0f;   // millimolar (in i_NaK)
    const float Km_Na       = 40.0f;   // millimolar (in i_NaK)
    const float PNaK1       = PNaK;   // A_per_F (in i_NaK)
    const float i_NaK       = PNaK1*Ko/(Ko+Km_K)*y.Nai/(y.Nai+Km_Na)/(1.0f+0.1245f*exp(-0.1f*y.Vm*F/(R*T))+0.0353f*exp(-y.Vm*F/(R*T)));

    //IpCa
    const float KPCa        = 0.0005f;   // millimolar (in i_PCa)
    const float g_PCa       = 0.4125f;   // A_per_F (in i_PCa)
    const float i_PCa       = g_PCa*y.Cai/(y.Cai+KPCa);
    

    //Background currents
    const float g_b_Na      = 0.95f;   // S_per_F (in i_b_Na)
    const float i_b_Na      = g_b_Na*(y.Vm-E_Na);
    const float g_b_Ca      = 0.727272f;   // S_per_F (in i_b_Ca)
    const float i_b_Ca      = g_b_Ca*(y.Vm-E_Ca);

    //Sarcoplasmic reticulum
    const float i_up        = VmaxUp/(1.0f+pown(Kup,2)/pown(y.Cai,2));
    const float i_leak      = (y.Ca_SR-y.Cai)*V_leak;

    dy.g = 0e0f;

    //RyR
    const float RyRSRCass   = (1e0f - 1e0f/(1e0f +  exp((y.Ca_SR-0.3f)/0.1f)));
    const float i_rel       = g_irel_max*RyRSRCass*y.RyRo*y.RyRc*(y.Ca_SR-y.Cai);
    const float RyRainfss   = RyRa1-RyRa2/(1e0f + exp((1e+3f*y.Cai-(RyRahalf))/0.0082f));
    const float RyRtauadapt = 1e0f; //s
    
    dy.RyRa = (RyRainfss-y.RyRa)/RyRtauadapt;

    const float RyRoinfss   = (1e0f - 1e0f/(1e0f +  exp((1e+3f*y.Cai-(y.RyRa+ RyRohalf))/0.003f)));
    const float RyRtauact   = (RyRoinfss>= y.RyRo) ? 18.75e-3f : 0.1f*18.75e-3f;

    dy.RyRo                 = (RyRoinfss- y.RyRo)/RyRtauact;

    const float RyRcinfss   = (1e0f/(1e0f + exp((1e+3f*y.Cai-(y.RyRa+RyRchalf))/0.001f)));
    const float RyRtauinact = (RyRcinfss>= y.RyRc) ? 2*87.5e-3f : 87.5e-3f;

    dy.RyRc                 = (RyRcinfss- y.RyRc)/RyRtauinact;

    // Ca2+ buffering
    const float Buf_C       = 0.25f;   // millimolar (in calcium_dynamics)
    const float Buf_SR      = 10.0f;   // millimolar (in calcium_dynamics)
    const float Kbuf_C      = 0.001f;   // millimolar (in calcium_dynamics)
    const float Kbuf_SR     = 0.3f;   // millimolar (in calcium_dynamics)

    const float Cai_bufc    = 1.0f / (1.0f + (Buf_C*Kbuf_C)   / pown(y.Cai   + Kbuf_C , 2));
    const float Ca_SR_bufSR = 1.0f / (1.0f + (Buf_SR*Kbuf_SR) / pown(y.Ca_SR + Kbuf_SR, 2));
    

    /*printf("%e",i_Na);*/ //i_Na,i_NaL,i_b_Na,i_NaK,i_NaCa,i_fNa;

    // Ionic concentrations
    //Nai
    dy.Nai                  = -Cm*(i_Na + i_NaL + i_b_Na + 3.0f*i_NaK + 3.0f*i_NaCa + i_fNa)/(F*Vc);
    //caSR
    dy.Cai                  = Cai_bufc*(i_leak-i_up+i_rel - (i_CaL+i_b_Ca+i_PCa-2.0f*i_NaCa)*Cm/(2.0f*Vc*F) );
    //Cai
    dy.Ca_SR                = Ca_SR_bufSR*Vc/V_SR*(i_up-(i_rel+i_leak));

    // Membrane potential
    dy.Vm                   = -(i_K1 + i_to + i_Kr + i_Ks + i_CaL + i_NaK + i_Na + i_NaL + i_NaCa + i_PCa + i_f + i_b_Na + i_b_Ca);
    

    float dt = dx.w;

    //update
    y.Vm    += dt*dy.Vm;
    y.Ca_SR += dt*dy.Ca_SR;
    y.Cai   += dt*dy.Cai;
    y.g     += dt*dy.g;
    y.d     += dt*dy.d;
    y.f1    += dt*dy.f1;
    y.f2    += dt*dy.f2;
    y.fCa   += dt*dy.fCa;
    y.Xr1   += dt*dy.Xr1;
    y.Xr2   += dt*dy.Xr2;
    y.Xs    += dt*dy.Xs;
    y.h     += dt*dy.h;
    y.j     += dt*dy.j;
    y.m     += dt*dy.m;
    y.Xf    += dt*dy.Xf;
    y.q     += dt*dy.q;
    y.r     += dt*dy.r;
    y.Nai   += dt*dy.Nai;
    y.m_L   += dt*dy.m_L;
    y.h_L   += dt*dy.h_L;
    y.RyRa  += dt*dy.RyRa;
    y.RyRo  += dt*dy.RyRo;
    y.RyRc  += dt*dy.RyRc;
    
    //write
    vtx_yy[vtx1_idx1] = y;
    
   

    return;
}




//mono - fdm
kernel void vtx_diff(const  float4          dx,
                     global float4          *vtx_xx,
                     global float4          *vtx_uu,
                     global struct state    *vtx_yy)
{
    int3 vtx_dim = {get_global_size(0), get_global_size(1), get_global_size(2)};
    int3 vtx_pos = {get_global_id(0)  , get_global_id(1),   get_global_id(2)};
    int  vtx_idx = fn_idx1(vtx_pos, vtx_dim);
    
    
    //stencil
    float s = 0.0f;
    s += vtx_uu[fn_idx1(vtx_pos + (int3){1,0,0}, vtx_dim)].x;
    s += vtx_uu[fn_idx1(vtx_pos - (int3){1,0,0}, vtx_dim)].x;
    s += vtx_uu[fn_idx1(vtx_pos + (int3){0,1,0}, vtx_dim)].x;
    s += vtx_uu[fn_idx1(vtx_pos - (int3){0,1,0}, vtx_dim)].x;
    s += vtx_uu[fn_idx1(vtx_pos + (int3){0,0,1}, vtx_dim)].x;
    s += vtx_uu[fn_idx1(vtx_pos - (int3){0,0,1}, vtx_dim)].x;
    
    //scale
    float Au = (s - 6.0f*vtx_uu[vtx_idx].x)/(dx.x*dx.x);
    
    float dt = dx.w;


    vtx_uu[vtx_idx].x += dt*Au;   //monodomain update


    return;
}
