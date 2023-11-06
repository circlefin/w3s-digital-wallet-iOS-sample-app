// Copyright (c) 2023, Circle Technologies, LLC. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0 
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import { NextResponse } from 'next/server'
import { v4 } from "uuid";

export async function POST(request) {
    const user_id = v4();
    console.log(user_id)

    try {
        // Create user
        const res1 = await fetch(process.env.CIRCLE_BASE_URL + '/users', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.CIRCLE_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                'userId': user_id,
            }),
        });

        const data1 = await res1.json();

        console.log(data1);

        if(data1['code']) {
            return NextResponse.json(data1)
        }    

        // Get user token and secret key
        const res2 = await fetch(process.env.CIRCLE_BASE_URL + '/users/token', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.CIRCLE_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                'userId': user_id,
            }),
        });
        const data2 = await res2.json();

        console.log(data2);

        if(data2['code']) {
            return NextResponse.json(data2)
        }    

        // Get challenge id
        const res3 = await fetch(process.env.CIRCLE_BASE_URL + '/user/initialize', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.CIRCLE_API_KEY}`,
                'Content-Type': 'application/json',
                'X-User-Token': data2['data']['userToken'],
            },
            body: JSON.stringify({
                'idempotencyKey': v4(),
                'accountType': 'SCA',
                'blockchains': ["MATIC-MUMBAI"],
            }),
        });
        const data3 = await res3.json();

        console.log(data3);

        if(data3['code']) {
            return NextResponse.json(data3)
        }    

        return NextResponse.json({
            'userId': user_id,
            'userToken': data2['data']['userToken'],
            'encryptionKey': data2['data']['encryptionKey'],
            'challengeId': data3['data']['challengeId'],
        });
    } catch (e) {
        console.log(e);
        return NextResponse.json(e, { status: 500 });
    }
}
