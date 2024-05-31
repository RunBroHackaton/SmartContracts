const accessToken = 'ya29.a0AXooCgvFUiLOAd9rgNExgsvWBDx9L5QG_g3DeyAFL9zlbwpJHXU5M9Gnz3laJpEISZqCVn3ta9M3124oHNxKzZAXG8swRqq-24ExEKclV6Uj3tBgQdw4FKdfLZKW9E7NOkSz-cU7lX4HIOc6MvLxAif5MKC6B9-NKA2SaCgYKATkSARESFQHGX2MiGx18vaSRcTMEgDSifHzLAw0171';
const url = `https://www.googleapis.com/fitness/v1/users/me/dataSources?access_token=${accessToken}`;
const newRequest = Functions.makeHttpRequest({ url, headers: { 'Authorization': `Bearer ${accessToken}` } });
const newResponse = await newRequest;
if (newResponse.error) {
    throw new Error('Error fetching fitness data');
}
return Functions.encodeString(JSON.stringify(newResponse.data));
