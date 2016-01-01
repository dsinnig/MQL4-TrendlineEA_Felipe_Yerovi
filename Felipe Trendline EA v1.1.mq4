//+------------------------------------------------------------------+
//|                                          Felipe Trendline EA.mq4 |
//|                                       Copyright 2015, Wes Walton |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Wes Walton"
#property link      ""
#property version   "1.00"
#property strict

extern int Slippage=5;
extern int Max_Spread_Pips=5;
extern double Lots=0.01;

extern string Buy_Or_Sell="Buy";

extern int Profit_In_Pips=30;
extern int Stop_Loss_In_Pips=20;

extern int Move_Stop_At_Pips = 20;
extern int Move_Stop_To_Pips = 20;

extern bool Mail_Alert = false;
extern bool PopUp_Alert = false;
extern bool Sound_Alert = false;
extern bool SmartPhone_Notifications=false;

double UsePoint=Digits();
int UseSlippage=Slippage;

bool PlaceStops=false;

datetime TheTime;

bool BuysNotAllowed=false;
bool SellsNotAllowed=false;

int TheBox=9999;

double Price_Level_1;
bool RunEA=true;

int Tickets[1];

bool DrawLine=true;
bool BreakEven=true;
int Magic;

int OnInit()
{
   Magic = 456565;

   if(Digits()==2 || Digits()==3) UsePoint=0.01;
   if(Digits()==4 || Digits()==5) UsePoint=0.0001;
   
   if(Digits()==3 || Digits()==5) UseSlippage=Slippage*10;

   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   ObjectDelete("Trendline Bot Line");
}
void OnTick()
{
   if(BreakEven)
   {
      if(DrawLine) TrendLine();
      if(TheBox==1) CheckTrendLine();
      CheckProfit();
   }
}
void CheckTrendLine()
{
   Price_Level_1 = NormalizeDouble(ObjectGetValueByShift("Trendline Bot Line",0),Digits());

   if(Buy_Or_Sell=="Buy" && Bid>=Price_Level_1) {TheBox=9999;OpenTrade();return;}
   if(Buy_Or_Sell=="Sell" && Ask<=Price_Level_1) {TheBox=9999;OpenTrade();return;}
   
return;
}
void TrendLine()
{
   if(ObjectCreate(0,"Trendline Bot Line",OBJ_TREND,0,Time[10],High[10],Time[5],High[5]))
   {
      TheBox=MessageBox("Place trendline and press OK when ready","Trendline Placement",MB_OK);
   }
   DrawLine=false;
return;
}
void CheckProfit()
{
   if(OrderSelect(Tickets[0],SELECT_BY_TICKET))
   {
      if(PlaceStops)
      {
         if(Buy_Or_Sell=="Buy") bool m1 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(Stop_Loss_In_Pips*UsePoint),OrderOpenPrice()+(Profit_In_Pips*UsePoint),0,Green); 
         if(Buy_Or_Sell=="Sell") bool m2 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(Stop_Loss_In_Pips*UsePoint),OrderOpenPrice()-(Profit_In_Pips*UsePoint),0,Red); 
      }
      
      if(BreakEven && ((Buy_Or_Sell=="Buy" && Bid>=OrderOpenPrice()+(Move_Stop_At_Pips*UsePoint)) || (Buy_Or_Sell=="Sell" && Ask<=OrderOpenPrice()-(Move_Stop_At_Pips*UsePoint)))) 
      {
         Print("Trendline Move Stop Begin");
         BreakEven=false;
         
         if(Buy_Or_Sell=="Buy") bool m3 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(Move_Stop_To_Pips*UsePoint),OrderTakeProfit(),0,Green); 
         if(Buy_Or_Sell=="Sell") bool m4 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(Move_Stop_To_Pips*UsePoint),OrderTakeProfit(),0,Red); 
      }
   }
return;
}
void OpenTrade()
{
   PlaceStops=true;
   
   double TheSpread=MarketInfo(Symbol(),MODE_SPREAD);
   
   if(Digits()==3 || Digits()==5) TheSpread = MarketInfo(Symbol(),MODE_SPREAD)/10;
   
   if(TheSpread>Max_Spread_Pips) {Print("Spread too large, can't place trade");return;}

   if(Buy_Or_Sell=="Buy")
   {
      Tickets[0] = OrderSend(Symbol(),OP_BUY,Lots,Ask,UseSlippage,0,0,"Buy Trendline Trade: "+Symbol(),Magic,0,0);

      if(GetLastError()==4110) {BuysNotAllowed=true;return;}

      SendAlert("New Trendline Buy Trade on the "+Symbol());
   }
   if(Buy_Or_Sell=="Sell")
   {
      Tickets[0] = OrderSend(Symbol(),OP_SELL,Lots,Bid,UseSlippage,0,0,"Sell Trendline Trade: "+Symbol(),Magic,0,0);

      if(GetLastError()==4111) {SellsNotAllowed=true;return;}
         
      SendAlert("New Trendline Sell Trade on the "+Symbol());
   }
return;
}
void SendAlert(string Message)
{
   if(Mail_Alert) SendMail("New Rollover Finch Alert",Message);
   if(PopUp_Alert) Alert(Message);
   if(Sound_Alert) PlaySound("alert.wav");
   if(SmartPhone_Notifications) SendNotification(Message);
   return;
}