import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

export async function POST(request){
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL, anon=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
 const service=process.env.SUPABASE_SERVICE_ROLE_KEY, resend=process.env.RESEND_API_KEY;
 if(!url||!anon||!service||!resend||!process.env.NOTIFICATION_FROM) return NextResponse.json({enabled:false});
 const token=request.headers.get('authorization')?.replace(/^Bearer /,'');
 if(!token) return NextResponse.json({error:'Unauthorized'},{status:401});
 const authClient=createClient(url,anon,{auth:{persistSession:false}});
 const {data:{user},error:authError}=await authClient.auth.getUser(token);
 if(authError||!user) return NextResponse.json({error:'Unauthorized'},{status:401});
 let payload;try{payload=await request.json();}catch{return NextResponse.json({error:'Invalid payload'},{status:400});}
 const {bookingId,event}=payload||{};
 if(!/^[0-9a-f-]{36}$/i.test(bookingId||'')||!['created','updated'].includes(event)) return NextResponse.json({error:'Invalid request'},{status:400});
 const admin=createClient(url,service,{auth:{persistSession:false}});
 const {data:booking}=await admin.from('bookings').select('*').eq('id',bookingId).single();
 if(!booking||(user.id!==booking.customer_id&&user.id!==booking.provider_id))return NextResponse.json({error:'Not found'},{status:404});
 // This endpoint is a convenience notification, not a source of booking truth.
 // A verified production webhook is recommended to prevent repeat requests.
 if((event==='created'&&user.id!==booking.customer_id)||(event==='updated'&&user.id!==booking.provider_id&&user.id!==booking.customer_id))return NextResponse.json({error:'Forbidden'},{status:403});
 const recipient=event==='created'?process.env.BOYFRIEND_EMAIL:(user.id===booking.provider_id?process.env.SARAH_EMAIL:process.env.BOYFRIEND_EMAIL);
 if(!recipient) return NextResponse.json({enabled:false});
 const subject=event==='created'?`New request: ${booking.service_name}`:`Booking ${booking.status}: ${booking.service_name}`;
 const body=`Boyfriend Services\n\n${booking.service_name}\nStatus: ${booking.status}\nRequested date: ${booking.requested_at?new Date(booking.requested_at).toLocaleString('en-AU',{timeZone:'Australia/Brisbane'}):'To be arranged'}\nAdd-ons: ${(booking.addons||[]).join(', ')||'None'}\n\nOpen your private app to review.`;
 const resp=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${resend}`,'Content-Type':'application/json'},body:JSON.stringify({from:process.env.NOTIFICATION_FROM,to:[recipient],subject,text:body})});
 if(!resp.ok)return NextResponse.json({error:'Notification failed; booking remains saved'},{status:502});
 return NextResponse.json({sent:true});
}
