class AdshownController < ApplicationController
  def index
    xml = <<XML_END
<?xml version="1.0" encoding="UTF-8"?>
<TapjoyConnectReturnObject xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://tapjoyconnect.com/">
  <UserAccountObject>
    <EmailAddressVerified xsi:nil="true"/>
    <TotalTicketsAvailable xsi:nil="true"/>
    <TicketsEnteredInSweepstakes xsi:nil="true"/>
    <GameRank xsi:nil="true"/>
    <TapPoints>15</TapPoints>
    <PointsID>5a3de21f-a517-4e9c-ac21-6c3fb2e7ea4c</PointsID>
    <CurrencyName>Gold</CurrencyName>
  </UserAccountObject>
  <ChallengeListReturnObject>
    <ChallengeSummaries>
      <ChallengeInfoClass>
        <ChallengeID>718ca576-0b57-4297-a25e-b206bbd707e3</ChallengeID>
        <Name>Test 15</Name>
        <Description>This is a sample challenge.  It is for testing only.</Description>
        <StartDate>2009-10-07T00:00:00</StartDate>
        <EndDate>2009-10-31T00:00:00</EndDate>
        <LastOfferDate>2009-10-31T00:00:00</LastOfferDate>
        <MinAppVersion>1</MinAppVersion>
        <CostInPoints>20</CostInPoints>
        <Filter1>4 x 4</Filter1>
        <Filter2>4 letters</Filter2>
        <Filter3>Lite</Filter3>
        <Filter4>1 minute</Filter4>
        <MinScore1>30</MinScore1>
        <MinScore2>8</MinScore2>
        <MinScore3 xsi:nil="true"/>
        <MinScore4 xsi:nil="true"/>
        <MinScore5 xsi:nil="true"/>
        <MinScore6 xsi:nil="true"/>
        <MinScore7 xsi:nil="true"/>
        <MaxScore1 xsi:nil="true"/>
        <MaxScore2 xsi:nil="true"/>
        <MaxScore3 xsi:nil="true"/>
        <MaxScore4 xsi:nil="true"/>
        <MaxScore5 xsi:nil="true"/>
        <MaxScore6 xsi:nil="true"/>
        <MaxScore7 xsi:nil="true"/>
      </ChallengeInfoClass>
    </ChallengeSummaries>
  </ChallengeListReturnObject>
  <MoreDataAvailable>36</MoreDataAvailable>
  <Message>This is a basic description of what the Challenges system is.</Message>
  <Success xsi:nil="true"/>
</TapjoyConnectReturnObject>
XML_END
    
    respond_to do |f|
      f.xml {render(:text => xml)}
    end
  end
end