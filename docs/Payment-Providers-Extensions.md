# Payment Providers API 1.0 Extensions
This document describes extensions implemented by Zebra on top of the [Payment Providers API 1.0](https://developer.getsileo.app/payment-providers) specification.

## Support for multi-architecture packages
*Introduced in Zebra 1.1.29*

Zebra prior to 1.1.28 supported only the `iphoneos-arm` architecture. Starting with Zebra 1.1.29, architectures other than `iphoneos-arm` are supported. The most common of these is `iphoneos-arm64`. To enable payment providers to support multiple architectures, the `/package/:package_id/authorize_download` request now includes an `architecture` field, containing the value of the `Architecture:` field for the package in question.

## `payment_secret` without device passcode
*Introduced in Zebra 1.1.27*

Payment secrets, by definition, are secured by the user’s ability to authenticate themselves via their device’s enrolled biometric or passcode. Without any of these factors enabled on the user’s device, it logically isn’t possible to store the payment secret - the device isn’t secure enough to allow the user’s payment details to be stored.

The Payment Providers 1.0 spec leaves this situation undefined. Therefore, Zebra has chosen to address this by passing `null` as the value of `payment_secret` if it is unavailable.

Prior to Zebra 1.1.27, authentication would fail if a device passcode was not set.

## `/package/:package_id/info` optimisation while logged out
*Introduced in Zebra 1.1.23*

To allow payment providers to cache the `/package/:package_id/info` response, while logged out, Zebra will attempt a `GET` request, rather than the `POST` request specified by the Payment Providers 1.0 spec. If the response to the `GET` request is not in the 2xx status code range, Zebra will repeat the request as a standard `POST`, and all subsequent requests in the app session will also use the `POST` method.
