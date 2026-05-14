require "import"
import "android.widget.*"
import "android.app.*"
import "android.view.*"
import "android.content.*"
import "android.net.Uri"
import "com.androlua.Http"
import "cjson"

activity.setTitle("Islamic Hub Assistant")

prefs=activity.getSharedPreferences("app",0)
function getKey() return prefs.getString("k","") end
function saveKey(k) prefs.edit().putString("k",k).commit() end

function getLanguage() return prefs.getString("lang","urdu") end
function saveLanguage(lang) prefs.edit().putString("lang",lang).commit() end

layout={
  LinearLayout,
  orientation="vertical",
  padding="20dp",

  {
    TextView,
    text="ASSALAM O ALAIKUM",
    gravity="center",
    textSize="18sp"
  },

  {
    TextView,
    text="Developed by Friend Tech Resources Team",
    gravity="center"
  },

  {Button,id="hadith",text="Hadith"},
  {Button,id="quotes",text="Islamic Quotes"},
  {Button,id="advice",text="Islamic Advisory"},
  {Button,id="ayah",text="Ayah"},
  {Button,id="dua",text="Dua"},
  {Button,id="poetry",text="Islamic Poetry"},
  {Button,id="greeting",text="Greeting Messages"},
  {Button,id="more",text="More Options"}
}

activity.setContentView(loadlayout(layout))

local currentDialog=nil

function showLoading()
  local loadLayout={
    LinearLayout,
    orientation="vertical",
    padding="40dp",
    gravity="center",
    {
      ProgressBar,
      layout_width="48dp",
      layout_height="48dp"
    },
    {
      TextView,
      text="Loading... Please wait",
      paddingTop="20dp",
      gravity="center"
    }
  }
  
  local d=AlertDialog.Builder(activity)
  d.setCancelable(false)
  d.setView(loadlayout(loadLayout))
  currentDialog=d.show()
end

function hideLoading()
  if currentDialog ~= nil then
    currentDialog.dismiss()
    currentDialog=nil
  end
end

function showResult(title,msg)
  hideLoading()
  
  local d=AlertDialog.Builder(activity)
  d.setTitle(title)
  
  local lay={
    LinearLayout,
    orientation="vertical",
    padding="20dp",
    {
      TextView,
      text=msg,
      textIsSelectable=true,
      paddingBottom="15dp"
    },
    
    {
      LinearLayout,
      orientation="horizontal",
      gravity="center",
      layout_width="fill",
      {
        Button,
        text="Copy",
        layout_width="0dp",
        layout_weight="1",
        onClick=function()
          activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(msg)
          Toast.makeText(activity,"Copied!",0).show()
        end
      },
      
      {
        Button,
        text="Share",
        layout_width="0dp",
        layout_weight="1",
        onClick=function()
          local i=Intent(Intent.ACTION_SEND)
          i.setType("text/plain")
          i.putExtra(Intent.EXTRA_TEXT,msg)
          activity.startActivity(Intent.createChooser(i,"Share"))
        end
      }
    }
  }
  
  d.setView(loadlayout(lay))
  d.setPositiveButton("Close",nil)
  d.show()
end

function getPromptByLanguage(basePrompt)
  local lang=getLanguage()
  local langInstruction=""

  if lang=="urdu" then
    langInstruction="Urdu only. No extra text. No questions."
  elseif lang=="hindi" then
    langInstruction="Hindi only. No extra text. No questions."
  elseif lang=="english" then
    langInstruction="English only. No extra text. No questions."
  elseif lang=="romanurdu" then
    langInstruction="Roman Urdu only. No extra text. No questions."
  else
    langInstruction="Urdu only. No extra text. No questions."
  end

  return basePrompt.."\n"..langInstruction
end

function ai(prompt,cb)
  showLoading()
  
  Http.post(
    "https://api.groq.com/openai/v1/chat/completions",
    cjson.encode({
      model="llama-3.3-70b-versatile",
      messages={{
        role="user",
        content=getPromptByLanguage(prompt)
      }}
    }),
    {
      ["Authorization"]="Bearer "..getKey(),
      ["Content-Type"]="application/json"
    },
    function(c,r)
      if c==200 then
        local ok,d=pcall(cjson.decode,r)
        if ok and d and d.choices and d.choices[1] then
          cb(d.choices[1].message.content)
        else
          hideLoading()
          showResult("Error","Failed to parse response.")
        end
      else
        hideLoading()
        showResult("Error","Network Error: "..tostring(c))
      end
    end
  )
end

hadith.onClick=function()
  ai("Give authentic Hadith with book reference and hadith number",
  function(r) showResult("Hadith",r) end)
end

quotes.onClick=function()
  ai("Give Islamic quote",
  function(r) showResult("Quotes",r) end)
end

advice.onClick=function()
  ai("Give Islamic life advisory",
  function(r) showResult("Advisory",r) end)
end

ayah.onClick=function()
  ai("Give Quran Ayah with Arabic and translation",
  function(r) showResult("Ayah",r) end)
end

dua.onClick=function()
  ai("Give Dua with Arabic and translation",
  function(r) showResult("Dua",r) end)
end

poetry.onClick=function()
  ai("Give beautiful Islamic poetry in your language",
  function(r) showResult("Islamic Poetry",r) end)
end

function showGreetingMenu()
  local menu=AlertDialog.Builder(activity)
  menu.setTitle("Select Greeting Type")

  local greetingTypes={
    "Friday (Jummah) Greeting",
    "Eid Greeting",
    "Ramadan Greeting",
    "Islamic New Year Greeting",
    "Shab-e-Barat Greeting",
    "Miraj-un-Nabi Greeting",
    "General Islamic Greeting"
  }

  menu.setItems(greetingTypes,function(_,which)
    local prompt=""
    if which==0 then
      prompt="Give a beautiful Islamic Friday/Jummah greeting message"
    elseif which==1 then
      prompt="Give an Eid greeting message"
    elseif which==2 then
      prompt="Give a Ramadan greeting message"
    elseif which==3 then
      prompt="Give an Islamic New Year greeting message"
    elseif which==4 then
      prompt="Give a Shab-e-Barat greeting message"
    elseif which==5 then
      prompt="Give a Miraj-un-Nabi greeting message"
    else
      prompt="Give a general Islamic greeting message"
    end

    ai(prompt,function(msg)
      showResult("Greeting",msg)
    end)
  end)

  menu.show()
end

greeting.onClick=function()
  showGreetingMenu()
end

more.onClick=function()
  local d=AlertDialog.Builder(activity)
  d.setTitle("More Options")

  local lay={
    LinearLayout,
    orientation="vertical",
    padding="20dp",

    {TextView,text="API KEY (Groq API)",textSize="16sp",textColor="#FF9800"},
    {TextView,text="Get your API key from: console.groq.com",textSize="11sp",paddingBottom="5dp"},
    {EditText,id="keybox",hint="Enter Groq API Key",text=getKey() or ""},

    {
      Button,
      text="Save API Key",
      onClick=function()
        if keybox.text ~= "" then
          saveKey(keybox.text)
          Toast.makeText(activity,"API Key Saved",0).show()
        else
          Toast.makeText(activity,"Please enter API Key",0).show()
        end
      end
    },

    {TextView,text="",paddingTop="15dp"},

    {TextView,text="Language Selection",textSize="16sp",textColor="#FF9800"},
    {TextView,text="Current: "..getLanguage():upper(),textSize="14sp",paddingBottom="10dp"},

    {
      Button,
      text="Select Language",
      onClick=function()
        local langOptions={"Urdu","Hindi","English","Roman Urdu"}
        local langValues={"urdu","hindi","english","romanurdu"}
        
        local dialog=AlertDialog.Builder(activity)
        dialog.setTitle("Select Your Language")
        
        local currentLang=getLanguage()
        local selectedIndex=0
        for i=1,#langValues do
          if langValues[i]==currentLang then
            selectedIndex=i-1
            break
          end
        end
        
        dialog.setSingleChoiceItems(langOptions,selectedIndex,function(dlg,which)
          local newLang=langValues[which+1]
          saveLanguage(newLang)
          Toast.makeText(activity,"Language saved: "..langOptions[which+1],0).show()
          dlg.dismiss()
        end)
        
        dialog.setNegativeButton("Cancel",nil)
        dialog.show()
      end
    },

    {TextView,text="",paddingTop="15dp"},

    {
      Button,
      text="About",
      onClick=function()
        local dlg=AlertDialog.Builder(activity)
        dlg.setTitle("About")

        local about={
          ScrollView,
          {
            LinearLayout,
            orientation="vertical",
            padding="20dp",

            {TextView,text="Islamic Hub Assistant",textSize="18sp",gravity="center"},
            {TextView,text="Version 1.0",gravity="center",textSize="12sp"},
            {TextView,text="",paddingTop="5dp"},
            {TextView,text="Developed by Friend Tech Resources Team",gravity="center"},
            {TextView,text="Project by Bilal Ahmed",gravity="center"},
            {TextView,text="",paddingTop="10dp"},

            {TextView,
             text="Features:\n- Authentic Hadith\n- Quran Ayah\n- Islamic Dua\n- Islamic Quotes\n- Life Advisory\n- Islamic Poetry\n- Greeting Messages (Jummah, Eid, Ramadan, etc.)\n- Multi-Language Support (Urdu, Hindi, English, Roman Urdu)\n- Copy & Share Options",
             paddingTop="10dp",
             textSize="13sp"},

            {TextView,text="",paddingTop="10dp"},

            {Button,text="Feedback by Developer",
              onClick=function()
                activity.startActivity(Intent(Intent.ACTION_VIEW,
                Uri.parse("https://wa.me/923260836758")))
              end},

            {Button,text="Join My WhatsApp Group",
              onClick=function()
                activity.startActivity(Intent(Intent.ACTION_VIEW,
                Uri.parse("https://chat.whatsapp.com/FsiATGe2BAb2rfNWolL3k4")))
              end}
          }
        }

        dlg.setView(loadlayout(about))
        dlg.show()
      end
    }
  }

  d.setView(loadlayout(lay))
  d.show()
end