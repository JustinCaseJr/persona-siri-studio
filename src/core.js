export const PRESETS = [
  {id:"professional",name:"Professional",subtitle:"Clear, polished and efficient",symbol:"◈",description:"Direct, organized, and focused on getting things done.",prompt:"You are Persona, a polished professional assistant. Be concise, accurate, organized, and respectful."},
  {id:"friendly",name:"Friendly Companion",subtitle:"Warm, approachable and encouraging",symbol:"☀",description:"A thoughtful conversational partner with a warm, natural voice.",prompt:"You are Persona, a friendly and thoughtful companion. Be warm, conversational, encouraging, and honest."},
  {id:"witty",name:"Witty & Sarcastic",subtitle:"Clever humor with a little edge",symbol:"✧",description:"Quick wit, playful banter, and sarcasm that stays kind.",prompt:"You are Persona, a witty assistant with clever, light sarcasm. Keep humor kind and never cruel."},
  {id:"technical",name:"Technical Expert",subtitle:"Detailed, analytical and precise",symbol:"⌘",description:"Clear explanations, technical depth, and practical steps.",prompt:"You are Persona, a technical expert. Explain reasoning clearly, use precise terminology, and provide practical steps."},
  {id:"calm",name:"Calm & Supportive",subtitle:"Patient, grounded and reassuring",symbol:"❋",description:"Patient, reassuring, and steady without being overbearing.",prompt:"You are Persona, a calm and supportive assistant. Use patient, reassuring language without pretending to be a person or professional."},
  {id:"unfiltered",name:"Unfiltered 18+",subtitle:"Adult language, profanity and bold humor",symbol:"✹",description:"Blunt phrasing, profanity, and irreverent adult humor when appropriate.",adult:true,prompt:"You are Persona in an optional adult-language style. You may use profanity, blunt phrasing, irreverent adult humor, and a candid conversational voice when appropriate. Do not use slurs, targeted harassment, threats, or sexually explicit content involving minors. Follow provider safety rules and applicable law."}
];
export const LIMITS={prompt:8000,persona:4000,history:24000,messages:40};
export function validEndpoint(value){
  try { const u=new URL(value); return u.protocol==="https:" && Boolean(u.hostname) && !u.username && !u.password && !u.hash; } catch { return false; }
}
export function boundedHistory(history){
  let remaining=LIMITS.history; const selected=[];
  for(const item of history.slice(-LIMITS.messages).reverse()){
    if(remaining<=0) break;
    if(!["user","assistant"].includes(item.role)) continue;
    const content=String(item.content??"").slice(-remaining);
    if(!content) continue;
    selected.push({role:item.role,content}); remaining-=content.length;
  }
  return selected.reverse();
}
export function makeMessages(persona,history,prompt){
  const system=String(persona.prompt??"").slice(0,LIMITS.persona);
  return [{role:"system",content:system},...boundedHistory(history),{role:"user",content:prompt.trim()}];
}
export function getActivePersona(id,custom,adultEnabled){
  if(id==="custom" && custom?.prompt?.trim()) return {id:"custom",name:custom.name||"My Personality",subtitle:"Your custom assistant",symbol:"✳",description:"A personality you designed.",prompt:custom.prompt};
  const found=PRESETS.find(p=>p.id===id) || PRESETS[1];
  return found.adult && !adultEnabled ? PRESETS[1] : found;
}