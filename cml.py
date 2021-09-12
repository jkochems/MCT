# -*- coding: utf-8 -*-
"""
Created on Sat Sep 11 12:14:13 2021

@author: user
"""
# Let's go
# import pandas as pd
# import numpy as np
# 
# df = pd.read_csv("C:/Users/user/Dropbox/05_Wintersemester_2122/SummerCourse_CausalMachineLearning/Own_Project/Data/# north_cleaned_selected.csv")
# init_rown = len(df)
# df.replace([np.inf, -np.inf], np.nan, inplace=True)
# df[np.isfinite(df)]
# new_rown = len(df)
# print("Numbers of rows deleted {}".format(init_rown-new_rown))
# df.to_csv("C:/Users/user/Dropbox/05_Wintersemester_2122/SummerCourse_CausalMachineLearning/Own_Project/Data/north_cleaned_selected.csv")

from mcf import mcf_functions

outpfad = 'D:/Studium/Economics M.Res Mannheim/Summer Courses/Causal Machine Learning/Case study MA 2021/north/Results'
datpfad = 'D:/Studium/Economics M.Res Mannheim/Summer Courses/Causal Machine Learning/Case study MA 2021/north/Lasso'
indata = 'north_cleaned_selected'

d_name = ['ptype']          # Treatment
y_name = ['emplx_cum_30']          # List of outcome variables
x_name_ord = ['age', 'earn_x0', 'unem_x0', 'em_x0', 'olf_x0']
x_name_unord = ['nation', 'sex', 'school_use', 'voc_deg', 'region']
z_name_split_unord = ['school_use', 'voc_deg']
# x_name_ord = ['cont0', 'cont1']
# x_name_unord = ['cat1']
# z_name_list = ['cont0', 'cat1']
# z_name_split_ord = ['cont0']
# z_name_split_unord = ['cat1']
mp_parallel = 8
mp_with_ray = False   

# Worked
if __name__ == '__main__':
    mcf_functions.ModifiedCausalForest(
        outpfad=outpfad,
        datpfad=datpfad,
        indata=indata,
        d_name=d_name,
        y_name=y_name,
        x_name_unord=x_name_unord,
        x_name_ord=x_name_ord,
        z_name_split_unord=z_name_split_unord, 
        mp_with_ray=mp_with_ray,
        mp_parallel=mp_parallel,
        stop_empty = 5,
        boot=1000)   