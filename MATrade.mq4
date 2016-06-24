//+------------------------------------------------------------------+
//|                                                      MATrade.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict

#include <MA.mqh>

//+------------------------------------------------------------------+
//|   Input parameters                                               |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES InpTimeframe=PERIOD_H1;//Timeframe
//---
input uint MA_Period_Fast=10;//Period Fast
input uint MA_Period_Medium=18;//Period Medium
input uint MA_Period_Slow=42;//Period Slow
//---
input uint MA_Shift_Fast=0;//Shift Fast
input uint MA_Shift_Medium=2;//Shift Medium
input uint MA_Shift_Slow=5;//Shift Slow
//---
input ENUM_MA_METHOD MA_Method=MODE_EMA;//Method
input ENUM_APPLIED_PRICE MA_Applied_Price=PRICE_CLOSE;//Applied Price

input int InpMagicNumber=1;//Magic Number

//--- global vars
CMovingTrade moving;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!moving.SetFast(_Symbol,MA_Period_Fast,MA_Shift_Fast,MA_Method,MA_Applied_Price))return(INIT_FAILED);
   if(!moving.SetMedium(_Symbol,MA_Period_Medium,MA_Shift_Medium,MA_Method,MA_Applied_Price))return(INIT_FAILED);
   if(!moving.SetSlow(_Symbol,MA_Period_Slow,MA_Shift_Slow,MA_Method,MA_Applied_Price))return(INIT_FAILED);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(PositonTotal(_Symbol,TRADE_BUY)==0)
     {

      datetime last_time=0;
      if(!DealLastTime(TRADE_BUY,0,last_time))return;

      if(last_time<Time(_Symbol,InpTimeframe,0))
        {

         bool signal_buy=moving.Signal(TRADE_BUY,(ENUM_TIMEFRAMES)InpTimeframe,OPEN_METHOD_1|OPEN_METHOD_2);
         if(signal_buy)
           {
            if(!moving.Trade(_Symbol,TRADE_BUY,0.1,10,10))
               Print("Error ",moving.GetLastError());

           }

        }
     }
  }
//+------------------------------------------------------------------+
int PositonTotal(const string _symbol,const ENUM_TRADE_DIRECTION _dir)
  {
   int count=0;

#ifdef __MQL4__
   int total= OrdersTotal();
   for(int i=0;i<total;i++)
     {
      if(OrderSymbol()!=_symbol)
         continue;
      if(OrderType()==_dir)
         count++;
     }
#endif

#ifdef __MQL5__
   CPositionInfo pos;
   if(pos.Select(_symbol))
      count++;
#endif

   return(count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DealLastTime(const ENUM_TRADE_DIRECTION _dir,const int _magic,datetime &last_time)
  {
   last_time=0;
//---   
#ifdef __MQL4__   
   int orders_total=OrdersHistoryTotal();
   for(int i=orders_total-1; i>=0; i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
         return(false);

      if(OrderSymbol()!=_Symbol)continue;
      if(OrderMagicNumber()!=_magic)continue;
      if(OrderType()!=_dir)continue;

      last_time=OrderOpenTime();

      break;
     }
#endif     


#ifdef __MQL5__
   CDealInfo deal;

   if(!HistorySelect(0,TimeCurrent()))
      return(false);

   int total=HistoryDealsTotal();
   for(int i=total-1; i>=0; i--)
     {
      if(!deal.SelectByIndex(i))
         return(false);

      if(deal.Symbol()!=_Symbol)
         continue;

      if(deal.Entry()==DEAL_ENTRY_IN)
         if((deal.DealType()==DEAL_TYPE_BUY && _dir==TRADE_BUY) ||
            (deal.DealType()==DEAL_TYPE_SELL && _dir==TRADE_SELL))
           {
            last_time=deal.Time();
            break;
           }
     }
#endif
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime Time(const string _symbol,const ENUM_TIMEFRAMES _tf,const int _index)
  {
#ifdef __MQL4__
   return(iTime(_symbol,_tf,_index));
#endif

#ifdef __MQL5__
   datetime ArTime[1]={0};
   CopyTime(_Symbol,_tf,0,1,ArTime);
   return(ArTime[0]);
#endif
  }
//+------------------------------------------------------------------+
