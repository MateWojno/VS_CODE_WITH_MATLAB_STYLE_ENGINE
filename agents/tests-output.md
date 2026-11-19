#Tests output
octave:23> test octave_dtree_platformer_v3.m                                                                                                                      
***** test                                                                                                                                                        
 % 1. Toolkit negotiation in --no-gui mode                                                                                                                        
 tk = display_select_toolkit({'fltk', 'qt'});                                                                                                                     
 assert(ischar(tk) && any(strcmp(tk, {'fltk', 'qt'})));                                                                                                           
!!!!! test failed                                                                                                                                                 
'display_select_toolkit' undefined near line 4, column 7  