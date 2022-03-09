using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraDepthOpenScript : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Camera currentCamera = GetComponent<Camera>();
        currentCamera.depthTextureMode |= DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
