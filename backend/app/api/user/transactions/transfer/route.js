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

import { NextRequest, NextResponse } from 'next/server'
import { v4 } from "uuid";
import { headers } from "next/headers";

export async function POST(request) {
    const req = await request.json()
    const userId = req['userId']
    const amounts = req['amounts']
    const destinationAddress = req['destinationAddress']
    const tokenId = req['tokenId']
    const walletId = req['walletId']
    const feeLevel = req['feeLevel']

    const requestHeaders = new Headers(request.headers);
    const userTokenFromHeader = requestHeaders.get('x-user-token');

    // Get user token and secret key
    const res = await fetch(process.env.CIRCLE_BASE_URL + '/user/transactions/transfer', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${process.env.CIRCLE_API_KEY}`,
            'Content-Type': 'application/json',
            'X-User-Token': userTokenFromHeader,
        },
        body: JSON.stringify({
            'userId': userId,
            'idempotencyKey': v4(),
            'amounts': amounts,
            'destinationAddress': destinationAddress,
            'tokenId': tokenId,
            'walletId': walletId,
            'feeLevel': feeLevel,
        }),
    });

    console.log({
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${process.env.CIRCLE_API_KEY}`,
            'Content-Type': 'application/json',
            'X-User-Token': userTokenFromHeader,
        },
        body: JSON.stringify({
            'userId': userId,
            'idempotencyKey': v4(),
            'amounts': amounts,
            'destinationAddress': destinationAddress,
            'tokenId': tokenId,
            'walletId': walletId,
            'feeLevel': feeLevel,
        }),
    });

    const data = await res.json();

    console.log(data);

    if (data['code']) {
        return NextResponse.json(data);
    }

    return NextResponse.json({
        'challengeId': data['data']['challengeId'],
    });
}
