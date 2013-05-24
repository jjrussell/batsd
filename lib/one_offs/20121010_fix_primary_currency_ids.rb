class OneOffs

   def self.fix_primary_currency_ids
     Currency.connection.execute("UPDATE currencies SET id = app_id WHERE app_id IN ( 'e3b80f30-6327-4048-ab13-60d00f6d7a82',
                                                                                      'c45e3a53-78b1-49e4-81c3-be8f84eb66e1',
                                                                                      'b3696928-c06b-4bd9-a617-71818a757c40',
                                                                                      'f2406991-9f66-4cfd-be96-649d70c3a85e',
                                                                                      '6ff12162-2a01-4bd0-bed4-5227bd268394',
                                                                                      '74507692-d8d0-49a2-8088-c2b205f0843f',
                                                                                      '73583cae-34c3-460d-a632-b517f3f56ec3',
                                                                                      '3a9d7dfb-6edc-4aba-8a9e-dcaffdde531b',
                                                                                      '97850bfe-d032-4484-bbac-9f3338a10523',
                                                                                      'c5277876-6f78-44d7-9898-1d84e8bb7e4d',
                                                                                      '6827dc39-87cb-4f26-811c-dd3a496f791f',
                                                                                      '6801253b-8cfe-420c-99c7-213f96e88e81',
                                                                                      'c01b658b-fe9f-4b77-88fd-301328f98fea',
                                                                                      'f7650f57-c80f-4078-b07e-fe031f423ce8',
                                                                                      '54f3cd55-0219-4eda-9319-c86bfb764c9b',
                                                                                      'c8a53726-c9d9-4de2-a2c2-68a0ba8702d8',
                                                                                      '8d1ea889-ed56-4280-afbb-554e559236ab',
                                                                                      '9dd63ae5-0163-467a-99a5-d98bd261537d',
                                                                                      'dac0264e-fc90-423b-8679-15f8e633cf72',
                                                                                      'fd368b6f-e6db-47f9-aca6-380abb8ad18a',
                                                                                      '4256ea60-c498-4d04-8c68-22a75ae8cebf',
                                                                                      'd5d62361-a24f-46f1-88ce-6e5dcdace7c0',
                                                                                      '8e1d3d31-e4df-440e-8832-bd3a37e465fe',
                                                                                      'f7f9b434-10a4-4936-99f4-c56ccea98345' ) AND conversion_rate > 0;")
  end
end
