-- FollowMe 1.0
-- by Muddle

local FM_COMMAND        = "@follow";
local FM_COMMAND_SENDER = "allow";
local FM_COMMAND_QUIET  = "quiet";
local FM_USE_SENDER     = "allow - add or remove a valid @follow command sender.";
local FM_USE_QUIET      = "quiet - suppress whispers back to the sender.";
local FM_FOLLOW_BEGIN   = "Following you.";
local FM_FOLLOW_END     = "I am not following you."
local FM_FOLLOW_RANGE   = "You are out of range to follow."

local following = nil;
local sender = nil;

settings = {
}

function FollowMe_LocalMsg(txt)
   DEFAULT_CHAT_FRAME:AddMessage(txt);
end

function FollowMe_OnLoad()
   
   SLASH_FOLLOWME1="/fm";
   SlashCmdList["FOLLOWME"] = FollowMe_CmdParser;   

   FollowMe_LocalMsg("FollowMe Loaded");   

   this:RegisterEvent("CHAT_MSG_WHISPER");   
   this:RegisterEvent("UI_ERROR_MESSAGE");
   this:RegisterEvent("AUTOFOLLOW_BEGIN");
   this:RegisterEvent("AUTOFOLLOW_END");
   this:RegisterEvent("PLAYER_LOGIN");

end

function FollowMe_CmdParser(msg)    

   local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

   if cmd == nil then
      FollowMe_LocalMsg("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      FollowMe_LocalMsg("FollowMe Commands:");      
      FollowMe_LocalMsg("    "..FM_USE_SENDER);
      FollowMe_LocalMsg("    "..FM_USE_QUIET);
      FollowMe_LocalMsg("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
      return;      
   end

   if strlower(cmd) == strlower(FM_COMMAND_SENDER) then           
      for k,v in pairs(settings.senders) do         
         if strupper(v) == strupper(args) then
            DEFAULT_CHAT_FRAME:AddMessage("FollowMe removing " .. args .. " from allow list.")
            table.remove(settings.senders, k)				
            return
         end         
      end
      if args ~= nil and strlen(args) ~= 0 then
         DEFAULT_CHAT_FRAME:AddMessage("FollowMe adding " .. args .. " to allow list.")      
         table.insert(settings.senders, args)
      else 
         DEFAULT_CHAT_FRAME:AddMessage("FollowMe accepting @follow from:")            
         for k,v in pairs(settings.senders) do            
            DEFAULT_CHAT_FRAME:AddMessage(v)
         end         
      end
   end

   if strlower(cmd) == strlower(FM_COMMAND_QUIET) then
      if settings.quiet == nil or settings.quiet == false then         
         DEFAULT_CHAT_FRAME:AddMessage("FollowMe quiet mode = true.")
         settings.quiet = true
      else 
         DEFAULT_CHAT_FRAME:AddMessage("FollowMe quiet mode = false.")
         settings.quiet = false
      end            
   end
      
end

function FollowMe_Whisper(name, message)
   if FollowMe_IsSenderAllowed(name) and 
      (settings.quiet == nil or settings.quiet == false) then 
      SendChatMessage(message, "WHISPER", nil, name);
   end   
end

function FollowMe_OnEvent(event)

   -- player login
   if event == "PLAYER_LOGIN" then      
      if settings == nil then 
         settings = {
            quiet = false,
            senders = {}
         }
      end
      if settings.senders == nil then
         settings["senders"] = {}
      end      
   end

   -- process message
   if event == "CHAT_MSG_WHISPER" then      
      if arg1 and arg2 then
         sender=arg2;
   	   FollowMe_ProcessWhisper(arg1, arg2);
      end
   end

   -- follow begin
   if event == "AUTOFOLLOW_BEGIN" then      
      if arg1 ~= nil then
         following=arg1;
         FollowMe_Whisper(following, FM_FOLLOW_BEGIN);        
      end
   end

   -- follow end
   if event == "AUTOFOLLOW_END" and following ~= nil then      
      FollowMe_Whisper(following, FM_FOLLOW_END);   
      following=nil;      
   end

   -- error 
   if event == "UI_ERROR_MESSAGE" then
      if arg1 == ERR_AUTOFOLLOW_TOO_FAR or 
         arg1 == ERR_INVALID_FOLLOW_TARGET or 
         arg1 == ERR_GENERIC_NO_TARGET then             
         if arg2 ~= nil then            
            FollowMe_Whisper(arg2, FM_FOLLOW_END);        
         end
      end      
   end

end

function FollowMe_ProcessWhisper(whisper, sender)   

   if not FollowMe_IsSenderAllowed(sender) then 
      return 
   end
   
   if whisper == "@follow" then
      TargetByName(sender, 1);
      if UnitExists("target") then
         FollowUnit("target");
      end
   end

end

function FollowMe_IsSenderAllowed(sender)
   for k,v in pairs(settings.senders) do      
      if strupper(v) == strupper(sender) then
         return true
      end      
   end
   return false
end