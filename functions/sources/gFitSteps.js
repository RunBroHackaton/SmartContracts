const url = 'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate';

const requestBody = {
  "aggregateBy": [
    {
      "dataTypeName": "com.google.step_count.delta",
      "dataSourceId": "derived:com.google.step_count.delta:com.google.android.gms:estimated_steps"
    }
  ],
  "bucketByTime": {
    "durationMillis": 86400000
  },
  "startTimeMillis": 1716242400000,
  "endTimeMillis": 1716882269739
};

console.log(`HTTP POST Request to ${url} with body: ${JSON.stringify(requestBody)}`);

const stepsRequest = await Functions.makeHttpRequest({
  url: url,
  method: "POST",
  headers: {
    "Authorization": `Bearer ${accessToken}`,
    "Content-Type": "application/json"
  },
  data: requestBody
});

// Execute the API request
let stepsResponse;
try {
  stepsResponse = await stepsRequest;
} catch (error) {
  console.error("Request failed:", error);
  throw new Error("Request failed");
}

// Parse the response and calculate total steps
const responseData = Buffer.isBuffer(stepsResponse.data) ? JSON.parse(stepsResponse.data.toString('utf-8')) : stepsResponse.data;
const totalSteps = responseData.bucket.reduce((total, bucket) => {
  if (bucket.dataset && bucket.dataset.length > 0 && bucket.dataset[0].point && bucket.dataset[0].point.length > 0) {
    return total + bucket.dataset[0].point.reduce((sum, point) => sum + (point.value[0].intVal || 0), 0);
  }
  return total;
}, 0);

console.log("Total Steps:", totalSteps);

return Functions.encodeUint256(totalSteps);
