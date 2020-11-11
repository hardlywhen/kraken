/*
 * Copyright (C) 2020 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#ifndef KRAKENBRIDGE_NODE_H
#define KRAKENBRIDGE_NODE_H

#include "eventTarget.h"
#include "include/kraken_bridge.h"
#include <array>
#include <vector>

namespace kraken::binding::jsc {

enum NodeType {
  ELEMENT_NODE = 1,
  TEXT_NODE = 3,
  COMMENT_NODE = 8,
  DOCUMENT_NODE = 9,
  DOCUMENT_TYPE_NODE = 10,
  DOCUMENT_FRAGMENT_NODE = 11
};

void bindNode(std::unique_ptr<JSContext> &context);

struct NativeNode;

class JSNode : public JSEventTarget {
public:
  JSNode() = delete;
  explicit JSNode(JSContext *context);
  explicit JSNode(JSContext *context, const char *name);

  class NodeInstance : public EventTargetInstance {
  public:
    enum class NodeProperty {
      kIsConnected,
      kFirstChild,
      kLastChild,
      kChildNodes,
      kPreviousSibling,
      kNextSibling,
      kAppendChild,
      kRemove,
      kInsertBefore,
      kReplaceChild,
      kNodeType,
      kNodeName
    };
    static std::array<JSStringRef, 12> &getNodePropertyNames();
    static const std::unordered_map<std::string, NodeProperty> &getNodePropertyMap();

    NodeInstance() = delete;
    NodeInstance(JSNode *node, NodeType nodeType);
    NodeInstance(JSNode *node, NativeNode *nativeNode, NodeType nodeType);
    ~NodeInstance() override;

    static JSValueRef appendChild(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                                  const JSValueRef arguments[], JSValueRef *exception);
    /**
     * The ChildNode.remove() method removes the object
     * from the tree it belongs to.
     * reference: https://dom.spec.whatwg.org/#dom-childnode-remove
     */
    static JSValueRef remove(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                             const JSValueRef arguments[], JSValueRef *exception);

    static JSValueRef insertBefore(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                                   const JSValueRef arguments[], JSValueRef *exception);

    static JSValueRef replaceChild(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount,
                                   const JSValueRef arguments[], JSValueRef *exception);

    JSValueRef getProperty(std::string &name, JSValueRef *exception) override;
    void setProperty(std::string &name, JSValueRef value, JSValueRef *exception) override;
    void getPropertyNames(JSPropertyNameAccumulatorRef accumulator) override;

    bool isConnected();
    JSNode::NodeInstance *firstChild();
    JSNode::NodeInstance *lastChild();
    JSNode::NodeInstance *previousSibling();
    JSNode::NodeInstance *nextSibling();
    void internalAppendChild(JSNode::NodeInstance *node);
    void internalRemove(JSValueRef *exception);
    JSNode::NodeInstance *internalRemoveChild(JSNode::NodeInstance *node, JSValueRef *exception);
    void internalInsertBefore(JSNode::NodeInstance *node, JSNode::NodeInstance *referenceNode);
    virtual JSStringRef internalTextContent();
    JSNode::NodeInstance *internalReplaceChild(JSNode::NodeInstance *newChild, JSNode::NodeInstance *oldChild);

    NodeType nodeType;
    JSNode::NodeInstance *parentNode{nullptr};
    std::vector<JSNode::NodeInstance *> childNodes;

  private:
    void ensureDetached(JSNode::NodeInstance *node);

    JSObjectRef _appendChild {nullptr};
    JSObjectRef _remove {nullptr};
    JSObjectRef _insertBefore {nullptr};
    JSObjectRef _replaceChild {nullptr};
  };
};

struct NativeNode : public NativeEventTarget {
  NativeNode() = delete;
  NativeNode(JSNode::NodeInstance *instance) : NativeEventTarget(instance) {};
};

} // namespace kraken::binding::jsc

#endif // KRAKENBRIDGE_NODE_H
