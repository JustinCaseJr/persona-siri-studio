import test from "node:test";
import assert from "node:assert/strict";
import {PRESETS,LIMITS,validEndpoint,boundedHistory,makeMessages,getActivePersona} from "../src/core.js";
test("includes the six personality presets",()=>assert.equal(PRESETS.length,6));
test("requires HTTPS provider endpoints without embedded credentials or fragments",()=>{
 assert.equal(validEndpoint("https://api.example.com/v1/chat/completions"),true);
 for(const value of ["http://api.example.com","https://user:pass@example.com/api","https://example.com/api#secret","not a url"]) assert.equal(validEndpoint(value),false);
});
test("bounds conversation context by message count and characters",()=>{
 const result=boundedHistory(Array.from({length:55},(_,i)=>({role:i%2?"assistant":"user",content:"x".repeat(1000)})));
 assert.ok(result.length<=LIMITS.messages);assert.ok(result.reduce((n,m)=>n+m.content.length,0)<=LIMITS.history);
});
test("keeps only user and assistant messages",()=>assert.deepEqual(boundedHistory([{role:"system",content:"no"},{role:"user",content:"yes"}]),[{role:"user",content:"yes"}]));
test("builds a system message, bounded history, and current prompt",()=>{
 const result=makeMessages(PRESETS[1],[{role:"user",content:"previous"}],"  hello  ");
 assert.equal(result[0].role,"system");assert.equal(result.at(-1).content,"hello");assert.equal(result.length,3);
});
test("adult preset is unavailable until acknowledged",()=>assert.equal(getActivePersona("unfiltered",{},false).id,"friendly"));
test("adult preset becomes available after acknowledgement",()=>assert.equal(getActivePersona("unfiltered",{},true).id,"unfiltered"));
test("uses custom personality when instructions exist",()=>assert.equal(getActivePersona("custom",{name:"Test",prompt:"Be concise"},false).name,"Test"));
