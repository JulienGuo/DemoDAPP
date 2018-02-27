package com.java.test.client;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.security.KeyStore;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class HttpsClientUtil {

    public static SSLContext getSSLContext() throws Exception {
        TrustManager[] tm = {new MyX509TrustManager()};
        SSLContext sslContext = SSLContext.getInstance("SSL", "SunJSSE");
        sslContext.init(null, tm, new SecureRandom());
        return sslContext;
    }

    /**
     * 根据装置的证书密钥初始化SSLContext
     *
     * @return
     * @throws Exception
     */
    public static SSLContext getSSLContext(String mchId, String keyStorePath) throws Exception {
        KeyManagerFactory keyManagerFactory = KeyManagerFactory
                .getInstance(KeyManagerFactory.getDefaultAlgorithm());
        // 获得密钥库  
        KeyStore keyStore = loadKeyStore(mchId, keyStorePath);
        // 初始化密钥工厂  
        keyManagerFactory.init(keyStore, mchId.toCharArray());
        SSLContext sslContext = SSLContext.getInstance("SSL");
        TrustManager[] tm = {new MyX509TrustManager()};
        sslContext.init(keyManagerFactory.getKeyManagers(), tm, new SecureRandom());
        return sslContext;
    }

    /**
     * 根据商户ID，加载安全密钥
     *
     * @param mchId
     */
    public static KeyStore loadKeyStore(String mchId, String keyStorePath) throws Exception {
        // 实例化密钥库 KeyStore用于存放证书，创建对象时 指定交换数字证书的加密标准
        //指定交换数字证书的加密标准 
        KeyStore keyStore = KeyStore.getInstance("PKCS12");//PKCS12
        try {
            InputStream instream = new FileInputStream(keyStorePath);
            keyStore.load(instream, mchId.toCharArray());
            instream.close();
        } catch (Exception e) {
            // TODO: handle exception
            throw e;
        }
        return keyStore;
    }

    /**
     * 发送请求.
     *
     * @param httpsUrl    请求的地址
     * @param requestData 请求的数据
     */
    public static String httpsRequest(String mchId, String cerPath, String requestMethod, String httpsUrl, String requestData) {
        // 声明SSL上下文  
        SSLContext sslContext = null;
        // 实例化主机名验证接口  
        HostnameVerifier hnv = new MyHostnameVerifier();
        try {
            if (null == mchId && null == cerPath) {
                sslContext = getSSLContext();
            } else {
                sslContext = getSSLContext(mchId, cerPath);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "E1";
        }
        try {
            URL url = new URL(null, httpsUrl, new sun.net.www.protocol.https.Handler());//指定URLStreamHandler 防止 weblogic报错
            HttpsURLConnection urlCon = (HttpsURLConnection) url.openConnection();
            if (null != sslContext) {
                SSLSocketFactory ssf = sslContext.getSocketFactory();
                urlCon.setSSLSocketFactory(ssf);
            }
            urlCon.setHostnameVerifier(hnv);
            urlCon.setDoInput(true);
            urlCon.setDoOutput(true);
            // 设置请求方式（GET/POST）
            urlCon.setRequestMethod(requestMethod);
            urlCon.setRequestProperty("Content-Length", String.valueOf(requestData.getBytes().length));
            urlCon.setUseCaches(false);
            urlCon.getOutputStream().write(requestData.getBytes("utf-8"));
            urlCon.getOutputStream().flush();
            urlCon.getOutputStream().close();
            BufferedReader in = new BufferedReader(new InputStreamReader(
                    urlCon.getInputStream(), "UTF-8"));
            String line;
            StringBuilder result = new StringBuilder();
            while ((line = in.readLine()) != null) {
                String str = new String(line.getBytes());
                result.append(str);
            }
            System.out.println(result.toString());
            return result.toString();
        } catch (Exception e) {
            e.printStackTrace();
            return "E2";
        }
    }

    public static void main(String[] args) {
        String jsondataReq = "{\"openId\":\"QJWD001\",\"orderInfo\":{\"insurantCertificateNo\":\"510128196811220939\",\"insurantName\":\"张永强\",\"insurantPhone\":\"13982208002\",\"orderNo\":\"56670114576295113957\",\"packageCode\":\"PK00002691\",\"planCode\":\"MP02000062\",\"productCode\":\"MP02000062\"},\"policyInfo\":{\"insuranceBeginDate\":\"2017-08-01 00:00:00\",\"insuranceEndDate\":\"2017-08-07 00:00:00\",\"policyNo\":\"12695033900190098261\"}}";
        httpsRequest("123456", "cert/client.p12", "POST", "https://10.20.16.135:8088/v1/channel1peerorg1/policy", jsondataReq);
    }

    static class MyX509TrustManager implements X509TrustManager {

        /**
         * 该方法检查客户端的证书，若不信任该证书则抛出异常。
         */
        @Override
        public void checkClientTrusted(X509Certificate[] arg0, String arg1)
                throws CertificateException {
            // TODO Auto-generated method stub

        }

        /**
         * 该方法检查服务器的证书，若不信任该证书同样抛出异常。
         */
        @Override
        public void checkServerTrusted(X509Certificate[] arg0, String arg1)
                throws CertificateException {
            // TODO Auto-generated method stub

        }

        /**
         * 返回受信任的X509证书数组
         */
        @Override
        public X509Certificate[] getAcceptedIssuers() {
            // TODO Auto-generated method stub
            return null;
        }
    }

    static class MyHostnameVerifier implements HostnameVerifier {
        @Override
        public boolean verify(String hostname, SSLSession session) {
            return true;
        }
    }
}