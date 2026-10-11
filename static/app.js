document.addEventListener("DOMContentLoaded", () => {
    // =====================================================
    // 1. ĐỒ THỊ KIẾN THỨC
    // =====================================================
    const el = document.getElementById("graph");

    if (el && window.vis) {
        // Tăng kích thước vùng đồ thị
        el.style.width = "100%";
        el.style.height = "min(85vh, 950px)";
        el.style.minHeight = "700px";
        el.style.border = "1px solid #dbe3f0";
        el.style.borderRadius = "12px";
        el.style.background = "#ffffff";

        // Tạo thanh công cụ
        const toolbar = document.createElement("div");
        toolbar.className = "graph-toolbar";
        toolbar.style.cssText = `
            display:flex;
            flex-wrap:wrap;
            gap:8px;
            align-items:center;
            margin:12px 0;
        `;

        const makeButton = (label, title, action) => {
            const button = document.createElement("button");
            button.type = "button";
            button.textContent = label;
            button.title = title;
            button.style.cssText = `
                padding:9px 14px;
                border:1px solid #cbd5e1;
                border-radius:8px;
                background:#ffffff;
                color:#1e3a8a;
                cursor:pointer;
                font-size:14px;
            `;
            button.addEventListener("click", action);
            toolbar.appendChild(button);
            return button;
        };

        // Đặt thanh công cụ ngay phía trên đồ thị
        el.parentNode.insertBefore(toolbar, el);

        fetch(el.dataset.url)
            .then(response => {
                if (!response.ok) {
                    throw new Error("Không tải được dữ liệu đồ thị.");
                }
                return response.json();
            })
            .then(data => {
                const nodesData = data.nodes || [];
                const edgesData = (data.edges || []).filter(edge =>
                    edge && edge.source && edge.target
                );

                if (!nodesData.length) {
                    el.textContent = "Chưa có dữ liệu khái niệm để hiển thị.";
                    return;
                }

                // Dịch nhãn quan hệ sang tiếng Việt
                const relationLabels = {
                    IS_A: "Là một",
                    IS_SPECIAL_CASE_OF: "Là trường hợp đặc biệt của",
                    RELATED_TO: "Có liên quan",
                    HAS_PROPERTY: "Có tính chất",
                    HAS_THEOREM: "Có định lý",
                    HAS_FORMULA: "Có công thức",
                    HAS_TIP: "Có mẹo học",
                    HAS_EXERCISE: "Có bài tập",
                    APPLIES_TO: "Áp dụng cho"
                };

                // Tạo node
                const nodes = new vis.DataSet(
                    nodesData
                        .filter(node => node && node.id)
                        .map(node => ({
                            id: node.id,
                            label: node.name || node.id,
                            shape: "box",
                            margin: {
                                top: 14,
                                right: 20,
                                bottom: 14,
                                left: 20
                            },
                            widthConstraint: {
                                maximum: 200
                            },
                            font: {
                                size: 18,
                                face: "Arial",
                                color: "#172554"
                            },
                            color: {
                                background: "#e8edff",
                                border: "#3157d5",
                                highlight: {
                                    background: "#dbeafe",
                                    border: "#1d4ed8"
                                },
                                hover: {
                                    background: "#dbeafe",
                                    border: "#1d4ed8"
                                }
                            },
                            borderWidth: 1.5,
                            shapeProperties: {
                                borderRadius: 10
                            },
                            chosen: {
                                node: (values) => {
                                    values.borderWidth = 3;
                                }
                            }
                        }))
                );

                // Tạo cạnh và tránh ID trùng
                const edges = new vis.DataSet(
                    edgesData.map((edge, index) => ({
                        id: `edge-${index}`,
                        from: edge.source,
                        to: edge.target,
                        label: relationLabels[edge.label] || edge.label || "Quan hệ",
                        arrows: {
                            to: {
                                enabled: true,
                                scaleFactor: 0.7
                            }
                        },
                        color: {
                            color: "#94a3b8",
                            highlight: "#3157d5",
                            hover: "#64748b"
                        },
                        font: {
                            size: 13,
                            face: "Arial",
                            color: "#334155",
                            strokeWidth: 3,
                            strokeColor: "#ffffff",
                            align: "middle"
                        },
                        width: 1.4,
                        smooth: {
                            enabled: true,
                            type: "dynamic"
                        }
                    }))
                );

                // Cấu hình lực đẩy để các node cách xa nhau
                const options = {
                    autoResize: true,

                    layout: {
                        improvedLayout: true,
                        randomSeed: 42
                    },

                    nodes: {
                        shape: "box"
                    },

                    edges: {
                        smooth: {
                            enabled: true,
                            type: "dynamic",
                            roundness: 0.35
                        }
                    },

                    interaction: {
                        dragNodes: true,
                        dragView: true,
                        zoomView: true,
                        hover: true,
                        selectable: true,
                        navigationButtons: false,
                        keyboard: {
                            enabled: true
                        },
                        multiselect: true
                    },

                    physics: {
                        enabled: true,
                        solver: "forceAtlas2Based",

                        forceAtlas2Based: {
                            gravitationalConstant: -250,
                            centralGravity: 0.003,
                            springLength: 320,
                            springConstant: 0.025,
                            damping: 0.65,
                            avoidOverlap: 1
                        },

                        maxVelocity: 30,
                        minVelocity: 0.5,
                        timestep: 0.5,

                        stabilization: {
                            enabled: true,
                            iterations: 1500,
                            updateInterval: 50,
                            fit: true
                        }
                    }
                };

                const network = new vis.Network(
                    el,
                    { nodes, edges },
                    options
                );

                // Các nút điều khiển
                makeButton(
                    "⟳ Sắp xếp lại",
                    "Chạy lại thuật toán sắp xếp để giãn các node",
                    () => {
                        network.setOptions({
                            physics: {
                                enabled: true,
                                solver: "forceAtlas2Based",
                                forceAtlas2Based: {
                                    gravitationalConstant: -250,
                                    centralGravity: 0.003,
                                    springLength: 320,
                                    springConstant: 0.025,
                                    damping: 0.65,
                                    avoidOverlap: 1
                                },
                                stabilization: {
                                    enabled: true,
                                    iterations: 1000,
                                    fit: true
                                }
                            }
                        });

                        network.stabilize(1000);
                    }
                );

                makeButton(
                    "⊞ Vừa màn hình",
                    "Hiển thị toàn bộ đồ thị",
                    () => network.fit({
                        animation: {
                            duration: 500,
                            easingFunction: "easeInOutQuad"
                        }
                    })
                );

                makeButton(
                    "＋ Phóng to",
                    "Phóng to đồ thị",
                    () => {
                        const scale = network.getScale();
                        network.moveTo({
                            scale: Math.min(scale * 1.25, 2.5),
                            animation: true
                        });
                    }
                );

                makeButton(
                    "－ Thu nhỏ",
                    "Thu nhỏ đồ thị",
                    () => {
                        const scale = network.getScale();
                        network.moveTo({
                            scale: Math.max(scale / 1.25, 0.15),
                            animation: true
                        });
                    }
                );

                makeButton(
                    "↺ Đặt lại",
                    "Đưa đồ thị về bố cục ban đầu",
                    () => {
                        network.setOptions({
                            physics: { enabled: true }
                        });

                        network.setData({ nodes, edges });
                        network.stabilize(1000);

                        setTimeout(() => {
                            network.fit({
                                animation: {
                                    duration: 500,
                                    easingFunction: "easeInOutQuad"
                                }
                            });
                        }, 300);
                    }
                );

                // Kéo node xong thì giữ vị trí, không để lực đẩy
                // tự làm các node di chuyển trở lại.
                network.on("dragEnd", params => {
                    if (params.nodes && params.nodes.length) {
                        network.storePositions();
                        network.setOptions({
                            physics: {
                                enabled: false
                            }
                        });
                    }
                });

                // Nhấp đúp vào khái niệm để mở trang chi tiết
                network.on("doubleClick", params => {
                    if (params.nodes && params.nodes.length) {
                        const nodeId = params.nodes[0];
                        window.location.href =
                            "/concept/" + encodeURIComponent(nodeId);
                    }
                });

                // Hoàn tất bố cục ban đầu
                network.once("stabilizationIterationsDone", () => {
                    network.fit({
                        animation: {
                            duration: 400,
                            easingFunction: "easeInOutQuad"
                        }
                    });
                });
            })
            .catch(error => {
                console.error("Lỗi tải đồ thị:", error);
                el.textContent = "Không tải được đồ thị. Hãy kiểm tra kết nối Neo4j.";
            });
    }

    // =====================================================
    // 2. CHẤM BÀI TẬP — GIỮ NGUYÊN CHỨC NĂNG CŨ
    // =====================================================
    document.querySelectorAll(".submit").forEach(button => {
        button.addEventListener("click", async () => {
            const card = button.closest(".exercise");
            if (!card) return;

            let answer = "";

            if (card.dataset.type === "MCQ") {
                const selected = card.querySelector("input:checked");

                if (!selected) {
                    alert("Hãy chọn đáp án.");
                    return;
                }

                answer = selected.value;
            } else {
                const input = card.querySelector(".answer");
                answer = input ? input.value.trim() : "";

                if (!answer) {
                    alert("Hãy nhập đáp án.");
                    return;
                }
            }

            button.disabled = true;
            const box = card.querySelector(".feedback");

            if (!box) {
                button.disabled = false;
                return;
            }

            try {
                const response = await fetch(
                    "/api/exercise/" +
                    encodeURIComponent(card.dataset.id) +
                    "/submit",
                    {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify({ answer })
                    }
                );

                const result = await response.json();

                if (!response.ok) {
                    throw new Error(result.error || "Lỗi chấm bài.");
                }

                box.hidden = false;
                box.className =
                    "feedback mt-3 " +
                    (result.correct ? "good" : "bad");
                box.replaceChildren();

                const heading = document.createElement("h3");
                heading.textContent = result.correct
                    ? "Chính xác!"
                    : "Chưa chính xác — hãy xem lại lời giải.";
                box.append(heading);

                const answerText = document.createElement("p");
                answerText.textContent =
                    "Đáp án: " +
                    (result.correct_answer || "Chưa cập nhật");
                box.append(answerText);

                if (result.solution) {
                    const solution = document.createElement("p");
                    solution.textContent =
                        "Lời giải: " + result.solution;
                    box.append(solution);
                }

                if (
                    Array.isArray(result.solution_steps) &&
                    result.solution_steps.length
                ) {
                    const list = document.createElement("ol");

                    result.solution_steps.forEach(step => {
                        const item = document.createElement("li");
                        item.textContent = step;
                        list.append(item);
                    });

                    box.append(list);
                }

                if (
                    Array.isArray(result.related) &&
                    result.related.length
                ) {
                    const related = document.createElement("p");
                    related.textContent =
                        "Kiến thức liên quan: " +
                        result.related
                            .map(item => item.name || item.label)
                            .join(", ");
                    box.append(related);
                }

                if (
                    Array.isArray(result.recommendations) &&
                    result.recommendations.length
                ) {
                    const headingRecommendations =
                        document.createElement("h4");

                    headingRecommendations.textContent =
                        "Bài tập gợi ý";
                    box.append(headingRecommendations);

                    result.recommendations.forEach(item => {
                        const paragraph = document.createElement("p");
                        paragraph.textContent =
                            (item.difficulty || "") +
                            " — " +
                            (item.question || item.id);
                        box.append(paragraph);
                    });
                }
            } catch (error) {
                box.hidden = false;
                box.textContent =
                    error.message || "Có lỗi xảy ra khi chấm bài.";
            } finally {
                button.disabled = false;
            }
        });
    });
});