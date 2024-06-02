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
  "startTimeMillis": 1716847200000,
  "endTimeMillis": 1716882269739
}

console.log(`HTTP POST Request to ${url} with body: ${JSON.stringify(requestBody)}`)

async function fetchSteps() {
  const stepsRequest = Functions.makeHttpRequest({
    url: url,
    method: "POST",
    headers: {
      "Authorization": "Bearer ya29.a0AXooCgvxf0OeAqgu6p3SjXlBwAZk9tXrHCOKaqCrPUr_9OowUk6wiAdPxR9pwLo3dABNQ8s8lbJYol_ps_zUjRHjih9B6evruoef38GIQ7BtbbkzJIj77bKJ_R4J-pFBlCeH1sXpfnvv9nNPJAULAxtpSwcQZViCZ3jiaCgYKAWQSARISFQHGX2MiAA0rsfwcobvAnD5ovf8fDA0171",
      "Content-Type": "application/json"
    },
    data: JSON.stringify(requestBody)
  })

  // Execute the API request
  const stepsResponse = await stepsRequest

  if (stepsResponse.error) {
    throw Error("Request failed")
  }
  // Parse the response and calculate total steps
  const responseData = Buffer.isBuffer(stepsResponse.data) ? JSON.parse(stepsResponse.data.toString('utf-8')) : stepsResponse.data;
  const totalSteps = responseData.bucket.reduce((total, bucket) => {
    if (bucket.dataset && bucket.dataset.length > 0 && bucket.dataset[0].point && bucket.dataset[0].point.length > 0) {
      return total + bucket.dataset[0].point.reduce((sum, point) => sum + (point.value[0].intVal || 0), 0);
    }
    return total;
  }, 0);

  console.log("Total Steps:", totalSteps)

  return Functions.encodeString(totalSteps.toString())
}

// Call the async function
fetchSteps().catch(error => console.error(error));
