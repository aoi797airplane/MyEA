//+------------------------------------------------------------------+
//|                                    average-directional-index.mq4 |
//|        ©2011 Best-metatrader-indicators.com. All rights reserved |
//|                        http://www.best-metatrader-indicators.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011 Best-metatrader-indicators.com."
#property link      "http://www.best-metatrader-indicators.com"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 DodgerBlue
#property indicator_color2 Tomato
#property indicator_color3 Gold
//---- input parameters
extern int ADXPeriod=14;
//---- buffers
double ADXBuffer[];
double PlusDiBuffer[];
double MinusDiBuffer[];
double PlusSdiBuffer[];
double MinusSdiBuffer[];
double TempBuffer[];
string Copyright="\xA9 WWW.BEST-METATRADER-INDICATORS.COM";  
string MPrefix="FI";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 3 additional buffers are used for counting.
   IndicatorBuffers(6);
//---- indicator buffers
   SetIndexBuffer(0,ADXBuffer);
   SetIndexBuffer(1,PlusDiBuffer);
   SetIndexBuffer(2,MinusDiBuffer);
   SetIndexBuffer(3,PlusSdiBuffer);
   SetIndexBuffer(4,MinusSdiBuffer);
   SetIndexBuffer(5,TempBuffer);
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("ADX("+ADXPeriod+")");
   SetIndexLabel(0,"ADX");
   SetIndexLabel(1,"+DI");
   SetIndexLabel(2,"-DI");
//----
   SetIndexDrawBegin(0,ADXPeriod);
   SetIndexDrawBegin(1,ADXPeriod);
   SetIndexDrawBegin(2,ADXPeriod);
//----
   DL("001", Copyright, 5, 20,Gold,"Arial",10,0); 
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   ClearObjects(); 
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   double pdm,mdm,tr;
   double price_high,price_low;
   int    starti,i,counted_bars=IndicatorCounted();
//----
   i=Bars-2;
   PlusSdiBuffer[i+1]=0;
   MinusSdiBuffer[i+1]=0;
   if(counted_bars>=i) i=Bars-counted_bars-1;
   starti=i;
//----
   while(i>=0)
     {
      price_low=Low[i];
      price_high=High[i];
      //----
      pdm=price_high-High[i+1];
      mdm=Low[i+1]-price_low;
      if(pdm<0) pdm=0;  // +DM
      if(mdm<0) mdm=0;  // -DM
      if(pdm==mdm) { pdm=0; mdm=0; }
      else if(pdm<mdm) pdm=0;
           else if(mdm<pdm) mdm=0;
      //---- 
      double num1=MathAbs(price_high-price_low);
      double num2=MathAbs(price_high-Close[i+1]);
      double num3=MathAbs(price_low-Close[i+1]);
      tr=MathMax(num1,num2);
      tr=MathMax(tr,num3);
      //---- counting plus/minus direction
      if(tr==0) { PlusSdiBuffer[i]=0; MinusSdiBuffer[i]=0; }
      else      { PlusSdiBuffer[i]=100.0*pdm/tr; MinusSdiBuffer[i]=100.0*mdm/tr; }
      //----
      i--;
     }
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   int limit=Bars-counted_bars;
//---- apply EMA to +DI
   for(i=0; i<=limit; i++)
      PlusDiBuffer[i]=iMAOnArray(PlusSdiBuffer,Bars,ADXPeriod,0,MODE_EMA,i);
//---- apply EMA to -DI
   for(i=0; i<=limit; i++)
      MinusDiBuffer[i]=iMAOnArray(MinusSdiBuffer,Bars,ADXPeriod,0,MODE_EMA,i);
//---- Directional Movement (DX)
   i=Bars-2;
   TempBuffer[i+1]=0;
   i=starti;
   while(i>=0)
     {
      double div=MathAbs(PlusDiBuffer[i]+MinusDiBuffer[i]);
      if(div==0.00) TempBuffer[i]=0;
      else TempBuffer[i]=100*(MathAbs(PlusDiBuffer[i]-MinusDiBuffer[i])/div);
      i--;
     }
//---- ADX is exponential moving average on DX
   for(i=0; i<limit; i++)
      ADXBuffer[i]=iMAOnArray(TempBuffer,Bars,ADXPeriod,0,MODE_EMA,i);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| DL function                                                      |
//+------------------------------------------------------------------+
 void DL(string label, string text, int x, int y, color clr, string FontName = "Arial",int FontSize = 12, int typeCorner = 1)
 
{
   string labelIndicator = MPrefix + label;   
   if (ObjectFind(labelIndicator) == -1)
   {
      ObjectCreate(labelIndicator, OBJ_LABEL, 0, 0, 0);
  }
   
   ObjectSet(labelIndicator, OBJPROP_CORNER, typeCorner);
   ObjectSet(labelIndicator, OBJPROP_XDISTANCE, x);
   ObjectSet(labelIndicator, OBJPROP_YDISTANCE, y);
   ObjectSetText(labelIndicator, text, FontSize, FontName, clr);
  
}  

//+------------------------------------------------------------------+
//| ClearObjects function                                            |
//+------------------------------------------------------------------+
void ClearObjects() 
{ 
  for(int i=0;i<ObjectsTotal();i++) 
  if(StringFind(ObjectName(i),MPrefix)==0) { ObjectDelete(ObjectName(i)); i--; } 
}
//+------------------------------------------------------------------+