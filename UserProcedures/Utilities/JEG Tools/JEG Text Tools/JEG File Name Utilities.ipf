 JEG File Name Utilities.ipf�B @@�q���x������M�    ���xTEXTIGR0 ����      7  ���kF��ɽ                       ��Z  // -*-Igor-*-// ###################################################################//  Igor Pro - JEG Tools// //  FILE: "JEG File Name Utilities"//                                    created: 8/13/1998 {10:07:02 AM} //                                last update: 8/14/1998 {11:02:20 AM} //  Author: Jonathan Guyer//  E-mail: <jguyer@his.com>//     www: http://www.his.com/~jguyer///  //  Description: // //  History// //   modified  by  rev reason//  ---------- --- --- -----------//  8/13/1998  JEG 1.0 original// ###################################################################// #pragma rtGlobals=1		// Use modern global access method.// // -------------------------------------------------------------------------// // "JEG_FindNumberAtEnd" --// //  Given a string "base345", returns the position of "3", i.e., 4.// -------------------------------------------------------------------------// Function JEG_FindNumberAtEnd(aString)	String aString		String numbers = "1234567890"		Variable pos = strlen(aString) - 1		do		if (strsearch(numbers,aString[pos],0) < 0)			pos += 1			break		endif				pos -= 1			while (pos > 0)		return posEnd// // -------------------------------------------------------------------------// // "JEG_BaseAndNumber" --// //  Given a string "base345", returns "base;345;"// -------------------------------------------------------------------------// Function/S JEG_BaseAndNumber(aString)	String aString		Variable pos = JEG_FindNumberAtEnd(aString)	aString[pos] = ";"	aString += ";"		return aStringEnd                                                                              V  V   ee-->           3,871 ratbert:TexJEG File Name Utilities   TEXT  TEXTIGR0 ����                  ��kF  7  �24 Normal File-->             172 ratbert:Text:Alpha 7.1fc5 �:Tcl:UserModifications:tclIndexx  Sent08/11/1998 21:45:27 Directory-   x    H H    �(�����FG(�    H H    �(    d       '                �     @                             F   �   H H H H $     $                                             @m�(      d                                             H Monaco a  3j������ ( DY�t4   ( � ( �����  �  �          V  V   eW53j    ^ MPSR  WMT1   6���        �     �l ���  l� ���   |    colors                                                                     