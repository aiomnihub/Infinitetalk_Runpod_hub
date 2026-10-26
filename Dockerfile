# Use specific version of nvidia cuda image
# Pinned (2026-10-26): ComfyUI and every custom node at their commit of 2026-05-15, the versions the
# workflow JSON files were made for. Unpinned clones built in October got ComfyUI v0.42, which refused the
# workflow with HTTP 400 on every job. Change a pin only together with the workflow JSON.
FROM wlsdml1114/engui_genai-base_blackwell:1.1@sha256:2b9a3c212c4b58a2490801458d84136004de232d612ecf38df00f66ad7734d74 as runtime

# wget 설치 (URL 다운로드를 위해)
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN pip install -U "huggingface_hub[hf_transfer]"
RUN pip install runpod websocket-client librosa

WORKDIR /

RUN git clone https://github.com/comfyanonymous/ComfyUI.git && git -C ComfyUI checkout 33ce449c8bdb && \
    cd /ComfyUI && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && git -C ComfyUI-Manager checkout 19f33695ff14 && \
    cd ComfyUI-Manager && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF && git -C ComfyUI-GGUF checkout 6ea2651e7df6 && \
    cd ComfyUI-GGUF && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-KJNodes && git -C ComfyUI-KJNodes checkout fca78c93f034 && \
    cd ComfyUI-KJNodes && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && git -C ComfyUI-VideoHelperSuite checkout 4ee72c065db2 && \
    cd ComfyUI-VideoHelperSuite && \
    pip install -r requirements.txt
    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/orssorbit/ComfyUI-wanBlockswap && git -C ComfyUI-wanBlockswap checkout 5fa2ec0fa558

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-MelBandRoFormer && git -C ComfyUI-MelBandRoFormer checkout 92c86854e665 && \
    cd ComfyUI-MelBandRoFormer && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && git -C ComfyUI-WanVideoWrapper checkout d18cdb18597f && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt


# RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy_GGUF/resolve/main/InfiniteTalk/Wan2_1-InfiniteTalk_Single_Q8.gguf -O /ComfyUI/models/diffusion_models/Wan2_1-InfiniteTalk_Single_Q8.gguf
# RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy_GGUF/resolve/main/InfiniteTalk/Wan2_1-InfiniteTalk_Multi_Q8.gguf -O /ComfyUI/models/diffusion_models/Wan2_1-InfiniteTalk_Multi_Q8.gguf
# RUN wget -q https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q8_0.gguf -O /ComfyUI/models/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf

RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/InfiniteTalk/Wan2_1-InfiniteTalk-Single_fp8_e4m3fn_scaled_KJ.safetensors -O /ComfyUI/models/diffusion_models/Wan2_1-InfiniteTalk-Single_fp8_e4m3fn_scaled_KJ.safetensors
RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/InfiniteTalk/Wan2_1-InfiniteTalk-Multi_fp8_e4m3fn_scaled_KJ.safetensors -O /ComfyUI/models/diffusion_models/Wan2_1-InfiniteTalk-Multi_fp8_e4m3fn_scaled_KJ.safetensors
RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors -O /ComfyUI/models/diffusion_models/Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors

RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors -O /ComfyUI/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors
RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors -O /ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors    
RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-fp8_e4m3fn.safetensors -O /ComfyUI/models/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors
RUN wget -q https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors -O /ComfyUI/models/clip_vision/clip_vision_h.safetensors
RUN wget -q https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp16.safetensors -O /ComfyUI/models/diffusion_models/MelBandRoformer_fp16.safetensors


# The ML libraries the nodes were written against (their versions of 2026-05-15). Unpinned, October's build got
# transformers 5.20, whose wav2vec2 returned no hidden states: MultiTalk failed with "'NoneType' object is not
# subscriptable" (2026-10-26). pip resolves their own dependencies.
RUN pip install "transformers==5.8.1" "diffusers==0.38.0" "accelerate==1.13.0" "peft==0.19.1"

COPY . .
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]