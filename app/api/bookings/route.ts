import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase-server';
export async function POST(req:NextRequest){
 try {const b=await req.json();const name=String(b.full_name||'').trim();const phone=String(b.phone||'').trim();const email=String(b.email||'').trim().toLowerCase();const quantity=Number(b.quantity);if(name.length<2||name.length>120||phone.length<7||phone.length>20||!/^\S+@\S+\.\S+$/.test(email)||!Number.isInteger(quantity)||quantity<1||quantity>10||!b.event_id||!b.ticket_category_id)return NextResponse.json({error:'Check your name, phone, email, event, ticket and quantity.'},{status:400});
 const db=await createClient();const {data,error}=await db.rpc('create_public_booking',{p_event_id:b.event_id,p_ticket_category_id:b.ticket_category_id,p_quantity:quantity,p_full_name:name,p_phone:phone,p_email:email});if(error)throw error;return NextResponse.json({booking:data});
 } catch(e:any){return NextResponse.json({error:e.message?.includes('SOLD_OUT')?'Sorry, there are not enough tickets remaining. Please choose a smaller quantity.':'Could not create booking. Check that the database setup is complete and try again.'},{status:400})}
}
